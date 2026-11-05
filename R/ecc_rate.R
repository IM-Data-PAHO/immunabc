#' (E)ligibility (C)onsistency (C)omparison Rate
#'
#' NOTE: Not exported. The eligibility criteria are currently being redefined, so this function should not be used for the time being.
#'
#' This function calculates the rate of eligibility consistency between the age at vaccination (\code{date_vax - date_birth}) and the expected age window defined in the vaccination schedule (\code{age_schedule_low}, \code{age_schedule_high}), further disaggregating by geographic level, using data from the electronic immunization registry (EIR).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param data.schedule Data frame. A data frame defining the vaccination schedule. See \code{immunABC.schedule} for expected structure.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis, disaggregating results by \code{dose}. If \code{NULL} (default), all doses in \code{data.schedule} are included and pooled together (no \code{dose} column in the output).
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame containing the eligibility rate (doses administered within the scheduled age window) and ineligibility rate (inverse proportion, including missing dates) in percentages for the specified \code{geo_level}.
#'
#' @import dplyr
#' @import lubridate
#'
#' @keywords internal
#' @noRd
ecc_rate <- function(data.EIR, data.schedule, geo_level = "ADM0", vaccines = NULL, birth_cohorts = NULL) {
  # NOTE: Unavailable until the eligibility criteria are redefined. The code below is kept for reference.
  message("ecc_rate is currently unavailable, since the eligibility criteria are being redefined.")
  return(invisible(NULL))


  # validations
  .validate_geo_level(geo_level)
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

  # Prepare EIR
  data.EIR <- data.EIR %>%
    rename(ADM1 = ADM1_residence, ADM2 = ADM2_residence)

  # determine doses to evaluate
  doses_to_use <- data.schedule %>%
    pull(dose) %>%
    unique()
  if(!is.null(vaccines)) {
    doses_to_use <- vaccines
  }

  # Selects group columns: by dose only when vaccines is specified, plus geo_level
  dose_group <- if(!is.null(vaccines)) "dose" else character(0)
  group_cols <- if (geo_level == "ADM1") {
      c(dose_group, "ADM1")
    } else if (geo_level == "ADM2") {
      c(dose_group, "ADM1", "ADM2")
    } else {
      dose_group
    }

  # prepare EIR with age at vaccination
  prepare_EIR <- data.EIR %>%
    filter(dose %in% doses_to_use) %>%
    mutate(age_at_vax = as.numeric(date_vax - date_birth))

  # Warns if any records were vaccinated before birth (points to dcc_ module)
  .validate_age_at_vax(prepare_EIR)

  # Calculates the ecc_rate
  ecc_rate <- prepare_EIR %>%
    left_join(data.schedule, by = "dose") %>%
    # Detects ineligible doses (outside the scheduled age window), also counts missing dates
    mutate(eligibility = case_when(
      is.na(date_vax) | is.na(date_birth) ~ "DATE_MISSING",
      age_at_vax < age_schedule_low | age_at_vax > age_schedule_high ~ "INELIGIBLE",
      TRUE ~ "ELIGIBLE"
    )) %>%
    # Groups by geo_level depending on choice of variables
    group_by(across(all_of(group_cols))) %>%
    # Counts eligibility
    count(eligibility) %>%
    # Totals and rates across groups (grouping preserved by count)
    mutate(
      total = sum(n),
      rate  = n / total * 100
    )

  # Returns summary table
  return(ecc_rate)
}
