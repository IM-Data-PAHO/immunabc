#' (V)accination (T)imeliness Inconsistent Records
#'
#' This function returns a record-level table of all untimely (early or late) and "date missing" vaccination records, including the number of days outside the timeliness window defined in the vaccination schedule.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param data.schedule Data frame. A data frame defining the vaccination schedule. See \code{immunABC.schedule} for expected structure.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all doses in \code{data.schedule} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which inconsistent records should be returned. If \code{NULL} (default), all available cohorts are used. Note that specifying cohorts excludes records with no \code{date_birth}, so the \code{DATE_MISSING} category may be undercounted.
#'
#' @return A data frame containing the untimely and date-missing records, with the following columns:
#' \itemize{
#'   \item \code{ID}: unique person identification number.
#'   \item \code{dose}: the dose.
#'   \item \code{date_birth}: date of birth.
#'   \item \code{date_vax}: date of vaccination.
#'   \item \code{age_at_vax}: age at vaccination in days.
#'   \item \code{age_schedule_low}, \code{age_schedule_high}: the timeliness window, from \code{data.schedule}.
#'   \item \code{days_outside_range}: the number of days outside of the timeliness window, negative if vaccinated before \code{age_schedule_low} and \code{NA} when a date is missing.
#'   \item \code{timeliness}: \code{UNTIMELY_EARLY} (before \code{age_schedule_low}), \code{UNTIMELY_LATE} (after \code{age_schedule_high}) or \code{DATE_MISSING}.
#' }
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
vt_inconsistent <- function(data.EIR, data.schedule, vaccines = NULL, birth_cohorts = NULL) {

  # validations
  .validate_data.schedule(data.schedule)
  .validate_data.EIR(data.EIR)
  .validate_schedule_doses(data.EIR, data.schedule)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_vaccines(vaccines, data.schedule, "data.schedule")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)

  # Prepares the table of inconsistent records
  vt_inconsistent <- .vt_classify(data.EIR, data.schedule, vaccines, birth_cohorts) %>%
    filter(timeliness %in% c("UNTIMELY_EARLY", "UNTIMELY_LATE", "DATE_MISSING")) %>%
    select(
      ID, dose, date_birth, date_vax, age_at_vax,
      age_schedule_low, age_schedule_high, days_outside_range, timeliness
    )

  # Returns the record-level table
  return(vt_inconsistent)
}
