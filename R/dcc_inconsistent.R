#' (D)ate (C)onsistency (C)omparison Inconsistent Records
#'
#' This function returns a record-level table of all inconsistent and "date missing" entries, including the day difference between the two dates.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param date_1 Character. The name of a DATE formatted variable present in the EIR. This variable is the date we are checking for consistency.
#' @param date_2 Character. The name of a DATE formatted variable present in the EIR. This variable is the date we are checking consistency against. Represents a date chronologically earlier than date_1.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which inconsistent records should be returned. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame containing the inconsistent records in the database and the time diferential between them.
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
dcc_inconsistent <- function(data.EIR, date_1, date_2, birth_cohorts = NULL) {

  # validations
  .validate_data.EIR(data.EIR, required_columns = .dcc_required_cols)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_date(data.EIR[[date_1]], date_1)
  .validate_date(data.EIR[[date_2]], date_2)

  # Checks if the birth_cohorts variable is used
  if (!is.null(birth_cohorts)) {
    data.EIR <- data.EIR %>%
      filter(year(date_birth) %in% birth_cohorts)
  }

  # Calculates the dcc_inconsistent
  dcc_inconsistent <- data.EIR %>%
    # Detects inconsistencies, also counts missing dates
    mutate(consistency = case_when(.data[[date_2]] > .data[[date_1]] ~  "INCONSISTENT",
                                  is.na(.data[[date_2]]) | is.na(.data[[date_1]]) ~ "DATE_MISSING",
                                  TRUE ~ "CONSISTENT")) %>%
    filter(consistency %in% c("INCONSISTENT", "DATE_MISSING")) %>%
    mutate(diff = .data[[date_1]] - .data[[date_2]]) %>%
    select(ID, dose, all_of(c(date_2, date_1)), consistency, diff)

  #Returns summary table
  return(dcc_inconsistent)
}