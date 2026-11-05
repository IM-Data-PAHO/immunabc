#' Dose (S)equence (C)omparison Rate
#'
#' This function checks, for each person, whether the doses they received of an ordered dose sequence (e.g. DTP1, DTP2 and DTP3) are consistent, and calculates the percentage of consistent and inconsistent sequences, further disaggregating by geographic level of residence, using data from the electronic immunization registry (EIR).
#'
#' A sequence is consistent when both of the following hold:
#' \itemize{
#'   \item No earlier dose is skipped, i.e. the doses received are the first doses of the sequence. For a DTP1, DTP2, DTP3 sequence, "DTP1", "DTP1 + DTP2" and "DTP1 + DTP2 + DTP3" pass this check (the person may simply not have finished the sequence yet), while "DTP2", "DTP3", "DTP1 + DTP3" and "DTP2 + DTP3" do not.
#'   \item The doses received were administered in chronological order, i.e. each dose after the previous dose received in the sequence (e.g. DTP2 after DTP1).
#' }
#'
#' Only people with at least one dose of the sequence are evaluated. Since this is a nominal indicator, each person is assigned to a single place of residence (see \code{fix_residence}).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccines Character. A character vector of at least two doses with the ordered dose sequence to evaluate, e.g. \code{c("DTP1", "DTP2", "DTP3")}.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param aggregated Logical. Whether to pool all inconsistent sequences into a single \code{INCONSISTENT} category (TRUE, default), or keep \code{CONSISTENT} as a single category and show every inconsistent combination of doses received (FALSE), e.g. \code{"DTP1 + DTP3"}, flagging the ones administered out of chronological order (e.g. \code{"DTP1 + DTP2 (out of order)"}).
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. If \code{NULL} (default), all available cohorts are used.
#' @param allow_same_day Logical. Whether two consecutive doses administered on the same day are considered chronologically consistent. Default is \code{FALSE}, since doses of the same vaccine series should not be administered on the same day.
#' @param fix_residence Logical. When a person's residence differs across their records, whether to correct all of that person's records to the residence of their most recent vaccination (TRUE, default) or leave the data as-is (FALSE), in which case each person is assigned the residence of their first record.
#'
#' @return A data frame with one row per \code{sequence} category for the specified \code{geo_level}, with the following columns:
#' \itemize{
#'   \item \code{sequence}: the category of each sequence, one of:
#'   \itemize{
#'     \item \code{CONSISTENT}: no dose skipped and every dose administered in chronological order.
#'     \item \code{INCONSISTENT} (only when \code{aggregated = TRUE}): a dose was skipped and/or administered out of chronological order. When \code{aggregated = FALSE}, inconsistent sequences are shown as the combination of doses received, e.g. \code{"DTP1 + DTP3"} (missing DTP2), with the suffix \code{" (out of order)"} when the doses were not administered in chronological order.
#'     \item \code{DATE_MISSING}: no dose skipped and no chronological inconsistency found, but at least one dose received has no \code{date_vax}, so the chronological order cannot be fully evaluated.
#'   }
#'   \item \code{consistent}: whether that category corresponds to a consistent sequence (\code{NA} for \code{DATE_MISSING}).
#'   \item \code{n}: number of people in that category.
#'   \item \code{total}: total number of people with at least one dose of the sequence.
#'   \item \code{rate}: percentage of people in that category (\code{n / total * 100}).
#' }
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
sc_rate <- function(data.EIR, vaccines, geo_level = "ADM0", aggregated = TRUE, birth_cohorts = NULL, allow_same_day = FALSE, fix_residence = TRUE) {

  # validations
  .validate_data.EIR(data.EIR)
  .validate_sequence(vaccines, data.EIR)
  .validate_geo_level(geo_level)
  .validate_logical(aggregated, "aggregated")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_logical(allow_same_day, "allow_same_day")
  .validate_logical(fix_residence, "fix_residence")
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  # Selects group columns for geo_level
  group_cols <- .geo_level_cols(geo_level)

  # One row per person with the combination of doses received and its classification
  sequences <- .sc_prepare(
    data.EIR,
    vaccines,
    birth_cohorts,
    fix_residence,
    check_residence = geo_level != "ADM0"
  ) %>%
    .sc_classify_sequence(vaccines, allow_same_day)

  # consistent sequences are always pooled together, inconsistent ones only when aggregated
  sequences <- sequences %>%
    mutate(sequence = case_when(
      is.na(consistent) ~ "DATE_MISSING",
      consistent ~ "CONSISTENT",
      aggregated ~ "INCONSISTENT",
      out_of_order ~ paste0(sequence, " (out of order)"),
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
