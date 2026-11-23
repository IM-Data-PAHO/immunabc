#' (Z)ero (D)ose Rate
#'
#' This function computes the proportion of people that have no record of receiving a given set of vaccines using data from the electronic immunization registry (EIR).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0". Note also that if \code{data.pop} is in use, it must contain the columns to match.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all vaccines in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the zero-dose rate should be calculated. If \code{NULL} (default), every person is included regardless of birth year. With \code{data.pop}, this also means every year in the population table; years with no records in \code{data.EIR} will show a zero-dose rate of 100.
#' @param data.pop Data frame (optional). A data frame with population denominators. See \code{immunABC.pop.ADMX} for structure examples. If \code{NULL} (default) and no \code{data.pop_ids} is provided, the denominator is computed from \code{data.EIR}.
#' @param data.pop_ids Data frame (optional). A data frame with individual population records (such as a civil registry) that can be cross-referenced with the EIR. See \code{immunABC.pop_ids} for expected structure. If provided, denominators are computed from it instead of \code{data.pop} or \code{data.EIR}.
#' @return A data frame containing the zero-dose rate for each of the \code{vaccines}, birth cohort and geographic area, including groups where nobody was vaccinated. When \code{vaccines} is \code{NULL}, it also contains rows with \code{dose} "All", counting as vaccinated the people with at least one vaccine. A warning is raised when a group has more vaccinated people than population (negative \code{zd_rate}). To list each person and their vaccines, see \code{zd_list}.
#'
#' @import dplyr
#' @import lubridate
#' @import tidyr
#'
#' @export
zd_rate <- function(data.EIR, geo_level = "ADM0", vaccines = NULL, birth_cohorts = NULL, data.pop = NULL, data.pop_ids = NULL) {

  # validations
  .validate_geo_level(geo_level)
  # .validate_data.schedule(data.schedule)
  .validate_data.EIR(data.EIR)
  # .validate_schedule_doses(data.EIR, data.schedule)
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_data.pop(data.pop, geo_level)
  .validate_data.pop_ids(data.pop_ids)
  # .validate_vaccines(vaccines, data.schedule, "data.schedule")
  # .validate_logical(validate_doses, "validate_doses")

  # determine grouping column(s)
  groups <- c("birth_cohort", .geo_level_cols(geo_level))

  # determine vaccines to evaluate
  doses_to_use <- .doses_to_use(data.EIR, vaccines)

  # pick or compute denominators
  if(!is.null(data.pop_ids)) {
    # computing denominators from individualized records
    denominator <- .extract_denominators_from_population_data(data.pop_ids, groups, birth_cohorts)
  } else if(!is.null(data.pop)) {
    # copying denominators from population data
    denominator <- data.pop %>%
      # select age == 0 because this contains the population of age 0 for that year
      filter(age == 0) %>%
      rename(birth_cohort = year) %>%
      select(all_of(groups), population)
    if(!is.null(birth_cohorts)) {
      denominator <- denominator %>% filter(birth_cohort %in% birth_cohorts)
    }
  } else {
    denominator <- .extract_denominators_from_population_data(data.EIR, groups, birth_cohorts)
  }

  prepare_EIR <- .prepare_EIR_doses(data.EIR, doses_to_use, birth_cohorts)

  # get number of people with records in the EIR
  numerator <- prepare_EIR %>%
    group_by(dose, across(all_of(groups))) %>%
    summarise(numerator = n_distinct(ID), .groups = "drop")
  dose_labels <- doses_to_use

  # when no vaccines are specified, "All" counts people with at least one of them
  if(is.null(vaccines)) {
    numerator_all <- prepare_EIR %>%
      group_by(across(all_of(groups))) %>%
      summarise(numerator = n_distinct(ID), .groups = "drop") %>%
      mutate(dose = "All")
    numerator <- bind_rows(numerator, numerator_all)
    dose_labels <- c(doses_to_use, "All")
  }

  # compute zero-dose rate; groups with nobody vaccinated get a numerator of 0
  rate <- denominator %>%
    crossing(dose = dose_labels) %>%
    full_join(numerator, by = c("dose", groups)) %>%
    mutate(numerator = coalesce(numerator, 0L)) %>%
    select(dose, all_of(groups), numerator, population) %>%
    arrange(dose, across(all_of(groups))) %>%
    mutate(coverage = round(numerator / population * 100, 2)) %>%
    mutate(zd_rate = round(100 - coverage, 2))

  negative_rates <- sum(rate$zd_rate < 0, na.rm = TRUE)
  if(negative_rates > 0) {
    warning(paste0(negative_rates, " group(s) have more vaccinated people than population, so their zd_rate is negative."))
  }

  return(rate)
}
