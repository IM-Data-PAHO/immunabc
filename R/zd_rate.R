#' (Z)ero (D)ose Rate
#'
#' This function computes the proportion of people that have no record of receiving a given set of vaccines using data from the electronic immunization registry (EIR).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0". Note also that if \code{data.pop} is in use, it must contain the columns to match.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all vaccines in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the zero-dose rate should be calculated. If \code{NULL} (default), every person is included regardless of birth year. With \code{data.pop}, this also means every year in the population table; years with no records in \code{data.EIR} will show a zero-dose rate of 100.
#' @param data.pop Data frame (optional). A data frame with population denominators. See \code{immunABC.pop.ADMX} for structure examples. If \code{NULL} (default) and no \code{pop_ids} is provided, the denominator is computed from \code{data.EIR}.
#' @param data.pop_ids Data frame (optional). A data frame with civil records that allow cross-referencing identities with the EIR.population denominators. If provided, denominators are computed from it instead of the EIR or the population data frame.
#' @return A list of two elements. The first is a data frame containing the rate of zero-dose patients in the EIR for each of the \code{vaccines} provided, including groups where nobody was vaccinated. When \code{vaccines} is \code{NULL}, it also contains rows with \code{dose} "All", counting as vaccinated the people with at least one vaccine. A warning is raised when a group has more vaccinated people than population (negative \code{zd_rate}). The second is a data frame with one row per person, the earliest date of each of the \code{vaccines} and a \code{Vaccinated} column ("YES" if the person has at least one of them, "NO" otherwise); it includes \code{name} when \code{data.pop_ids} is provided, and is \code{NULL} when \code{data.pop} is used instead.
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

  # pick or compute denominators
  pop_data <- FALSE
  if(!is.null(data.pop_ids)){
    # computing denominators from individualized records
    denominator <- .extract_denominators_from_population_data(data.pop_ids, groups, birth_cohorts)
    pop_data <- TRUE
  } else if (!is.null(data.pop)) {
    # copying denominators from population data
    denominator <- data.pop %>%
      # select age == 0 because this contains the population of age 0 for that year
      filter(age == 0) %>%
      rename(birth_cohort = year) %>%
      select(all_of(groups), population)
    if (!is.null(birth_cohorts)) {
      denominator <- denominator %>% filter(birth_cohort %in% birth_cohorts)
    }
  } else {
    denominator <- .extract_denominators_from_population_data(data.EIR, groups, birth_cohorts)
    pop_data <- TRUE
  }

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
    filter(dose %in% doses_to_use) %>%
    mutate(
      birth_cohort = year(date_birth),
      age_at_vax = as.numeric(date_vax - date_birth)
    )

  # filter for selected birth cohorts
  if(!is.null(birth_cohorts)) {
    prepare_EIR <- prepare_EIR %>% filter(birth_cohort %in% birth_cohorts)
  }

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

  # build operative output if individual population records are available
  op_table <- NULL
  if (pop_data) {
    if (!is.null(data.pop_ids)) {
      pop_table <- data.pop_ids %>%
        select(
          ID,
          name,
          date_birth,
          ADM1_residence,
          ADM2_residence
        )
    } else {
      pop_table <- data.EIR %>%
        arrange(ID, date_vax) %>%
        distinct(ID, .keep_all = TRUE) %>%
        select(
          ID,
          date_birth,
          ADM1_residence,
          ADM2_residence
        )
    }
    if (!is.null(birth_cohorts)) {
      pop_table <- pop_table %>% filter(year(date_birth) %in% birth_cohorts)
    }

    # earliest date of each selected vaccine per person
    vacc_table <- prepare_EIR %>%
      group_by(ID, dose) %>%
      summarise(date_vax = min(date_vax), .groups = "drop") %>%
      pivot_wider(names_from = dose, values_from = date_vax)

    # vaccines nobody received still get their own (empty) column
    missing_doses <- setdiff(doses_to_use, names(vacc_table))
    vacc_table[missing_doses] <- as.Date(NA)
    vacc_table <- vacc_table %>% select(ID, all_of(doses_to_use))

    op_table <- pop_table %>%
      left_join(vacc_table, by = "ID") %>%
      mutate(Vaccinated = if_else(if_any(all_of(doses_to_use), ~ !is.na(.x)), "YES", "NO"))
  }

  return(list(rate, op_table))
}
