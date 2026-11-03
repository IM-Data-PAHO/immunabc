#' Dose (S)equence (C)omparison Inconsistent Records
#'
#' This function returns a person-level table of all inconsistent dose sequences (sequences where an earlier dose is skipped, e.g. DTP1 + DTP3), in a schedule-like format: one row per person and one column per dose of the sequence, containing the date the dose was administered.
#'
#' Only people with at least one dose of the sequence are evaluated. Since this is a nominal indicator, each person is assigned to a single place of residence (see \code{fix_residence}).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccines Character. A character vector of at least two doses with the ordered dose sequence to evaluate, e.g. \code{c("DTP1", "DTP2", "DTP3")}.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which inconsistent sequences should be returned. If \code{NULL} (default), all available cohorts are used.
#' @param fix_residence Logical. When a person's residence differs across their records, whether to correct all of that person's records to the residence of their most recent vaccination (TRUE, default) or leave the data as-is (FALSE), in which case each person is assigned the residence of their first record.
#'
#' @return A data frame with one row per person with an inconsistent sequence, with the following columns:
#' \itemize{
#'   \item \code{ID}: unique person identification number.
#'   \item \code{date_birth}: date of birth.
#'   \item \code{ADM1_residence}, \code{ADM2_residence}: place of residence.
#'   \item One column per dose in \code{vaccines}, in the order of the sequence: the date the dose was administered (the earliest one, if duplicated), or \code{NA} if it was not received (or was received with no \code{date_vax}).
#'   \item \code{sequence}: the combination of doses received, e.g. \code{"DTP1 + DTP3"}.
#'   \item \code{skipped_doses}: the doses of the sequence skipped, i.e. not received but followed by a dose that was received, e.g. \code{"DTP2"} for \code{"DTP1 + DTP3"}.
#' }
#'
#' @import dplyr
#' @import tidyr
#' @import lubridate
#'
#' @export
sc_inconsistent <- function(data.EIR, vaccines, birth_cohorts = NULL, fix_residence = TRUE) {

  # validations
  .validate_data.EIR(data.EIR)
  .validate_sequence(vaccines, data.EIR)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_logical(fix_residence, "fix_residence")
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  prepare_EIR <- .sc_prepare(data.EIR, vaccines, birth_cohorts, fix_residence)

  # People with an inconsistent sequence
  inconsistent <- prepare_EIR %>%
    .sc_classify_sequence(vaccines) %>%
    filter(!consistent)

  # Dates of each dose received, one column per dose
  dose_dates <- prepare_EIR %>%
    filter(ID %in% inconsistent$ID) %>%
    select(ID, dose, date_vax) %>%
    pivot_wider(names_from = dose, values_from = date_vax)

  # Adds the doses no one in the table received, so every dose of the sequence has a column
  for(vaccine in setdiff(vaccines, names(dose_dates))) {
    dose_dates[[vaccine]] <- as.Date(NA)
  }

  # Prepares the table of inconsistent sequences
  sc_inconsistent <- inconsistent %>%
    left_join(dose_dates, by = "ID") %>%
    mutate(
      # doses not received that come before the last dose received
      skipped_doses = vapply(
        str_split(sequence, fixed(" + ")),
        function(received) {
          before_last <- vaccines[seq_len(max(match(received, vaccines)))]
          paste(setdiff(before_last, received), collapse = " + ")
        },
        character(1)
      )
    ) %>%
    select(
      ID, date_birth,
      ADM1_residence = ADM1, ADM2_residence = ADM2,
      all_of(vaccines), sequence, skipped_doses
    )

  # Returns the person-level table
  return(sc_inconsistent)
}
