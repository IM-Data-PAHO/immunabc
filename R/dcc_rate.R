#' (D)ate (C)onsistency (C)omparison Rate
#'
#' This function calculates the rate of consistency between two date variables, further disaggregating by geographic level, using data from the electronic immunization registry (EIR).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param date_1 Character. The name of a DATE formatted variable present in the EIR. This variable is the date we are checking for consistency.
#' @param date_2 Character. The name of a DATE formatted variable present in the EIR. This variable is the date we are checking consistency against. Represents a date chronologically earlier than date_1.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame containing the consistency rate and inconsistency rate (inverse proportion) in percentages for the specified \code{geo_level}.
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
dcc_rate <- function(data.EIR, date_1, date_2, geo_level = "ADM0", birth_cohorts = NULL) {

  # validations
  .validate_data.EIR(data.EIR, required_columns = .dcc_required_cols)
  .validate_geo_level(geo_level)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_date(data.EIR[[date_1]], date_1)
  .validate_date(data.EIR[[date_2]], date_2)

  # Checks if the birth_cohorts variable is used
  if (!is.null(birth_cohorts)) {
    data.EIR <- data.EIR %>%
      filter(year(date_birth) %in% birth_cohorts)
  }

  #Prepare EIR
  data.EIR = data.EIR %>%
    rename(ADM1 = ADM1_residence, ADM2 =ADM2_residence)

  # Selects group columns for geo_level
  group_cols <- if (geo_level == "ADM1") {
      "ADM1"
    } else if (geo_level == "ADM2") {
      c("ADM1", "ADM2")
    } else {
      character(0)
    }
  # Calculates the dcc_rate
  dcc_rate <- data.EIR %>%
    # Detects inconsistencies, also counts missing dates
    mutate(consistency = case_when(.data[[date_2]] > .data[[date_1]] ~  "INCONSISTENT",
                                  is.na(.data[[date_2]]) | is.na(.data[[date_1]]) ~ "DATE_MISSING",
                                  TRUE ~ "CONSISTENT")) %>%
    # Groups by geo_level depending on choice of variables
    group_by(across(all_of(group_cols))) %>%
    #Counts consistency
    count(consistency) %>%
    # Totals and rates across groups (grouping preserved by count)
    mutate(
      total = sum(n),
      rate  = n / total * 100
    )

  #Returns summary table
  return(dcc_rate)
}