#' Dose (S)equence (C)omparison Date Sequence
#'
#' This function checks, for each person, whether the doses of an ordered dose sequence (e.g. DTP1, DTP2 and DTP3) were administered in chronological order, and calculates the percentage of sequences with a chronological inconsistency, further disaggregating by geographic level of residence, using data from the electronic immunization registry (EIR).
#'
#' Only the doses each person received are compared, so unfinished and inconsistent sequences are also evaluated (e.g. a person with DTP1 and DTP3 is checked for DTP1 before DTP3). People with fewer than two doses of the sequence cannot be evaluated and are excluded. Since this is a nominal indicator, each person is assigned to a single place of residence (see \code{fix_residence}).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccines Character. A character vector of at least two doses with the ordered dose sequence to evaluate, e.g. \code{c("DTP1", "DTP2", "DTP3")}.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. If \code{NULL} (default), all available cohorts are used.
#' @param allow_same_day Logical. Whether two consecutive doses administered on the same day are considered chronologically consistent. Default is \code{FALSE}, since doses of the same vaccine series should not be administered on the same day.
#' @param fix_residence Logical. When a person's residence differs across their records, whether to correct all of that person's records to the residence of their most recent vaccination (TRUE, default) or leave the data as-is (FALSE), in which case each person is assigned the residence of their first record.
#'
#' @return A data frame with one row per \code{chronology} category for the specified \code{geo_level}, with the following columns:
#' \itemize{
#'   \item \code{chronology}: the category of each sequence, one of:
#'   \itemize{
#'     \item \code{CONSISTENT}: every dose received was administered after the previous dose received in the sequence.
#'     \item \code{INCONSISTENT}: at least one dose was administered before (or, unless \code{allow_same_day = TRUE}, on the same day as) the previous dose received in the sequence.
#'     \item \code{DATE_MISSING}: at least one dose received has no \code{date_vax}.
#'   }
#'   \item \code{n}: number of people in that category.
#'   \item \code{total}: total number of people with at least two doses of the sequence.
#'   \item \code{rate}: percentage of people in that category (\code{n / total * 100}).
#' }
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
sc_date_sequence <- function(data.EIR, vaccines, geo_level = "ADM0", birth_cohorts = NULL, allow_same_day = FALSE, fix_residence = TRUE) {

  # validations
  .validate_data.EIR(data.EIR)
  .validate_sequence(vaccines, data.EIR)
  .validate_geo_level(geo_level)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_logical(allow_same_day, "allow_same_day")
  .validate_logical(fix_residence, "fix_residence")
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  # Selects group columns for geo_level
  group_cols <- if (geo_level == "ADM1") {
      "ADM1"
    } else if (geo_level == "ADM2") {
      c("ADM1", "ADM2")
    } else {
      character(0)
    }

  # Classifies the chronology of each person's sequence
  chronology <- .sc_prepare(
    data.EIR,
    vaccines,
    birth_cohorts,
    fix_residence,
    check_residence = geo_level != "ADM0"
  ) %>%
    # sort each person's doses following the order of the sequence
    mutate(dose_order = match(dose, vaccines)) %>%
    arrange(ID, dose_order) %>%
    group_by(ID, ADM1, ADM2) %>%
    # days since the previous dose received in the sequence
    mutate(days_since_previous = as.numeric(date_vax - lag(date_vax))) %>%
    summarise(
      n_doses = n(),
      date_missing = anyNA(date_vax),
      inconsistent = if(allow_same_day) {
        any(days_since_previous < 0, na.rm = TRUE)
      } else {
        any(days_since_previous <= 0, na.rm = TRUE)
      },
      .groups = "drop"
    ) %>%
    # sequences with a single dose cannot be evaluated
    filter(n_doses >= 2) %>%
    mutate(chronology = case_when(
      date_missing ~ "DATE_MISSING",
      inconsistent ~ "INCONSISTENT",
      TRUE ~ "CONSISTENT"
    ))

  # Calculates the sc_date_sequence rate
  sc_date_sequence <- chronology %>%
    group_by(across(all_of(group_cols))) %>%
    count(chronology) %>%
    # Totals and rates across groups (grouping preserved by count)
    mutate(
      total = sum(n),
      rate  = n / total * 100
    )

  # Returns summary table
  return(sc_date_sequence)
}
