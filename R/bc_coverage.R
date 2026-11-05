#' (B)irth (C)ohort Coverage
#' 
#' This function calculates the coverage by birth cohort, further disagreggating by geographic level, using data from the electronic immunization registry (EIR).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param data.schedule Data frame. A data frame defining the vaccination schedule. See \code{immunABC.schedule} for expected structure.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0". Note also that if \code{data.pop} is in use, it must contain the columns to match.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all vaccines in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which coverage should be calculated. If \code{NULL} (default), coverage is calculated for all available cohorts.
#' @param data.pop Data frame (optional). A data frame with population denominators. See \code{immunABC.pop.ADMX} for structure examples. If \code{NULL} (default), the denominator is taken from \code{data.EIR} for each year and \code{geo_level}.
#' @param validate_doses Logical (optional). If \code{TRUE} (default), only count vaccinations that occurred within the valid age window defined by \code{age_schedule_low} and \code{age_schedule_high}. If \code{FALSE}, does not validate doses before counting them.
#' 
#' @return A data frame containing the coverage by birth cohort for the specified \code{geo_level}.
#' 
#' @import dplyr
#' @import lubridate
#' 
#' @export
bc_coverage <- function(data.EIR, data.schedule, geo_level = "ADM0", vaccines = NULL, birth_cohorts = NULL, data.pop = NULL, validate_doses = TRUE) {

  # validations
  .validate_geo_level(geo_level)
  .validate_data.schedule(data.schedule)
  .validate_data.EIR(data.EIR)
  .validate_schedule_doses(data.EIR, data.schedule)
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_data.pop(data.pop, geo_level)
  .validate_vaccines(vaccines, data.schedule, "data.schedule")
  .validate_logical(validate_doses, "validate_doses")

  # determine grouping column(s)
  basic_groups <- c("birth_cohort")
  if(geo_level != "ADM0") {
    # groups for ADM1
    groups <- c(basic_groups, "ADM1")

    # groups for ADM2
    if(geo_level == "ADM2") {
      groups <- c(groups, geo_level)
    }
  } else {
    groups <- basic_groups
  }

  # determine vaccines to evaluate
  doses_to_use <- data.EIR %>%
    pull(dose) %>%
    unique()
  if(!is.null(vaccines)) {
    doses_to_use <- vaccines
  }

  # prepare schedule for selected doses
  prepare_schedule <- data.schedule %>%
    filter(dose %in% doses_to_use)

  # prepare EIR with valid age windows
  prepare_EIR <- data.EIR %>%
    select(
      ID,
      date_birth,
      date_vax,
      ADM1 = ADM1_residence,
      ADM2 = ADM2_residence,
      dose
    ) %>%
    filter(dose %in% prepare_schedule$dose) %>%
    mutate(
      birth_cohort = year(date_birth),
      age_at_vax = as.numeric(date_vax - date_birth)
    ) %>%
    left_join(prepare_schedule, by = "dose")

  if(validate_doses) {
    prepare_EIR <- prepare_EIR %>%
      filter(
        age_at_vax >= age_schedule_low,
        age_at_vax <= age_schedule_high
      )
  }

  # filter for selected birth cohorts
  if(!is.null(birth_cohorts)) {
    prepare_EIR <- prepare_EIR %>% filter(birth_cohort %in% birth_cohorts)
  }

  # get number of children with valid doses for the defined groups
  numerator <- prepare_EIR %>%
    group_by(dose, across(all_of(groups))) %>%
    summarise(numerator = n_distinct(ID), .groups = "drop")

  # get population for birth cohorts
  if(is.null(data.pop)) {
    line_list_denominator <- data.EIR %>%
      select(
        ID,
        date_birth,
        ADM1 = ADM1_residence,
        ADM2 = ADM2_residence
      ) %>%
      mutate(birth_cohort = year(date_birth))

    if(!is.null(birth_cohorts)) {
      line_list_denominator <- line_list_denominator %>%
        filter(birth_cohort %in% birth_cohorts)
    }

    line_list_denominator <- line_list_denominator %>%
      distinct(ID, across(all_of(groups)))

    denominator <- line_list_denominator %>%
      group_by(across(all_of(groups))) %>%
      summarise(population = n(), .groups = "drop")
  } else {
    denominator <- data.pop %>%
      # select age == 0 because this contains the population of age 0 for that year
      filter(age == 0) %>%
      select(-age) %>%
      rename(birth_cohort = year)
  }

  # calculate coverage
  coverage <- numerator %>%
    left_join(denominator, by = groups) %>%
    mutate(coverage = round(numerator / population * 100, 2))

  return(coverage)
}
