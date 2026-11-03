#' Dose (S)equence (C)omparison Rate
#'
#' This function checks, for each person, whether the doses they received of an ordered dose sequence (e.g. DTP1, DTP2 and DTP3) are consistent, and calculates the percentage of consistent and inconsistent sequences, further disaggregating by geographic level of residence, using data from the electronic immunization registry (EIR).
#'
#' A sequence is consistent when no earlier dose is skipped, i.e. the doses received are the first doses of the sequence. For a DTP1, DTP2, DTP3 sequence, "DTP1", "DTP1 + DTP2" and "DTP1 + DTP2 + DTP3" are consistent (the person may simply not have finished the sequence yet), while "DTP2", "DTP3", "DTP1 + DTP3" and "DTP2 + DTP3" are inconsistent.
#'
#' Only people with at least one dose of the sequence are evaluated. Since this is a nominal indicator, each person is assigned to a single place of residence (see \code{fix_residence}).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccines Character. A character vector of at least two doses with the ordered dose sequence to evaluate, e.g. \code{c("DTP1", "DTP2", "DTP3")}.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param mode Character. Either \code{"simple"} (default), which classifies each sequence as \code{CONSISTENT} or \code{INCONSISTENT}, or \code{"complex"}, which keeps \code{CONSISTENT} as a single category and shows every inconsistent combination of doses received (e.g. \code{"DTP1 + DTP3"}).
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. If \code{NULL} (default), all available cohorts are used.
#' @param fix_residence Logical. When a person's residence differs across their records, whether to correct all of that person's records to the residence of their most recent vaccination (TRUE, default) or leave the data as-is (FALSE), in which case each person is assigned the residence of their first record.
#'
#' @return A data frame with one row per \code{sequence} category for the specified \code{geo_level}, with the following columns:
#' \itemize{
#'   \item \code{sequence}: \code{CONSISTENT}, or when \code{mode = "simple"}, \code{INCONSISTENT}. When \code{mode = "complex"}, inconsistent sequences are shown as the combination of doses received, e.g. \code{"DTP1 + DTP3"} (missing DTP2).
#'   \item \code{consistent}: whether that category corresponds to a consistent sequence.
#'   \item \code{n}: number of people in that category.
#'   \item \code{total}: total number of people with at least one dose of the sequence.
#'   \item \code{rate}: percentage of people in that category (\code{n / total * 100}).
#' }
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
sc_rate <- function(data.EIR, vaccines, geo_level = "ADM0", mode = "simple", birth_cohorts = NULL, fix_residence = TRUE) {

  # validations
  .validate_data.EIR(data.EIR)
  .validate_sequence(vaccines, data.EIR)
  .validate_geo_level(geo_level)
  .validate_sc_mode(mode)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_logical(fix_residence, "fix_residence")
  .validate_date(data.EIR$date_birth, "date_birth")

  # Selects group columns for geo_level
  group_cols <- if (geo_level == "ADM1") {
      "ADM1"
    } else if (geo_level == "ADM2") {
      c("ADM1", "ADM2")
    } else {
      character(0)
    }

  # One row per person with the combination of doses received
  sequences <- .sc_prepare(
    data.EIR,
    vaccines,
    birth_cohorts,
    fix_residence,
    check_residence = geo_level != "ADM0"
  ) %>%
    .sc_classify_sequence(vaccines)

  # consistent sequences are always pooled together, inconsistent ones only in simple mode
  sequences <- sequences %>%
    mutate(sequence = case_when(
      consistent ~ "CONSISTENT",
      mode == "simple" ~ "INCONSISTENT",
      TRUE ~ sequence
    ))

  # Calculates the sc_rate
  sc_rate <- sequences %>%
    group_by(across(all_of(group_cols))) %>%
    count(sequence, consistent) %>%
    # Totals and rates across groups (grouping preserved by count)
    mutate(
      total = sum(n),
      rate  = n / total * 100
    )

  # Returns summary table
  return(sc_rate)
}
