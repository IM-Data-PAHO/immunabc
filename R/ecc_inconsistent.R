#' (E)ligibility (C)onsistency (C)omparison Inconsistent Records
#'
#' NOTE: Not exported. The eligibility criteria are currently being redefined, so this function should not be used for the time being.
#'
#' This function returns a record-level table of all ineligible and "date missing" vaccination records, including the number of days outside the scheduled age window defined in the vaccination schedule (\code{age_schedule_low}, \code{age_schedule_high}).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param data.schedule Data frame. A data frame defining the vaccination schedule. See \code{immunABC.schedule} for expected structure.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all doses in \code{data.schedule} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which inconsistent records should be returned. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame containing the ineligible and date-missing records, with \code{ID}, \code{dose}, \code{date_birth}, \code{date_vax}, age at vaccination in days, the scheduled age window (\code{age_schedule_low}, \code{age_schedule_high}), and \code{days_outside_range}: the number of days outside that window, negative if vaccinated before \code{age_schedule_low}, positive if after \code{age_schedule_high} (\code{NA} when a date is missing).
#'
#' @import dplyr
#' @import lubridate
#'
#' @keywords internal
#' @noRd
ecc_inconsistent <- function(data.EIR, data.schedule, vaccines = NULL, birth_cohorts = NULL) {
  # NOTE: Unavailable until the eligibility criteria are redefined. The code below is kept for reference.
  message("ecc_inconsistent is currently unavailable, since the eligibility criteria are being redefined.")
  return(invisible(NULL))


  # validations
  .validate_data.schedule(data.schedule)
  .validate_data.EIR(data.EIR, data.schedule)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_vaccines(vaccines, data.schedule, "data.schedule")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)

  # Checks if the birth_cohorts variable is used
  if (!is.null(birth_cohorts)) {
    data.EIR <- data.EIR %>%
      filter(year(date_birth) %in% birth_cohorts)
  }

  # determine doses to evaluate
  doses_to_use <- data.schedule %>%
    pull(dose) %>%
    unique()
  if(!is.null(vaccines)) {
    doses_to_use <- vaccines
  }

  # prepare EIR with age at vaccination
  prepare_EIR <- data.EIR %>%
    filter(dose %in% doses_to_use) %>%
    mutate(age_at_vax = as.numeric(date_vax - date_birth))

  # Warns if any records were vaccinated before birth (points to dcc_ module)
  .validate_age_at_vax(prepare_EIR)

  # Calculates the ecc_inconsistent
  ecc_inconsistent <- prepare_EIR %>%
    left_join(data.schedule, by = "dose") %>%
    # Detects ineligible doses (outside the scheduled age window), also counts missing dates
    mutate(eligibility = case_when(
      is.na(date_vax) | is.na(date_birth) ~ "DATE_MISSING",
      age_at_vax < age_schedule_low | age_at_vax > age_schedule_high ~ "INELIGIBLE",
      TRUE ~ "ELIGIBLE"
    )) %>%
    filter(eligibility %in% c("INELIGIBLE", "DATE_MISSING")) %>%
    # Negative if vaccinated before age_schedule_low, positive if after age_schedule_high
    mutate(days_outside_range = case_when(
      eligibility == "DATE_MISSING" ~ NA_real_,
      age_at_vax < age_schedule_low ~ age_at_vax - age_schedule_low,
      age_at_vax > age_schedule_high ~ age_at_vax - age_schedule_high
    )) %>%
    select(
      ID, dose, date_birth, date_vax, age_at_vax,
      age_schedule_low, age_schedule_high, days_outside_range, eligibility
    )

  # Returns the record-level table
  return(ecc_inconsistent)
}
