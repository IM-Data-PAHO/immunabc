#' (No)minal (D)ropout Rate
#'
#' @param data.EIR A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccine_init Initial vaccine to use in nominal dropout calculation.
#' @param vaccine_end Final vaccine to use in nominal dropout calculation.
#' @param geo_level The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param birth_cohorts Birth cohorts to calculate for. As a vector of years.
#' @param fix_residence Logical. This function requires each person to have a single place of residence across all their vaccinations when geo_level is "ADM1" or "ADM2". When a person has more than one residence, TRUE (default) sets all their records to the residence of their most recent vaccination, and FALSE stops with an error.
#'
#' @return A data frame with two rows per geographic unit of residence: one for people who received \code{vaccine_init} but not \code{vaccine_end} (dropout) and one for people who received both (complete). People without \code{vaccine_init} are not counted. Columns:
#' \itemize{
#'   \item \code{ADM1_residence}, \code{ADM2_residence}: geographic unit of residence (will only appear depending on what is set in \code{geo_level}).
#'   \item \code{indicator}: A category: either \code{"dropout"} or \code{"complete"}.
#'   \item \code{num}: number of people in that category.
#'   \item \code{denom}: number of people who received \code{vaccine_init}.
#'   \item \code{percent}: \code{num / denom * 100}.
#' }
#'
#' @import tidyr
#' @import dplyr
#' @import lubridate
#'
#' @export
#'
#'
nod_dropout <- function(data.EIR, vaccine_init, vaccine_end, geo_level = "ADM0", birth_cohorts = NULL, fix_residence = TRUE) {

  .validate_character(vaccine_init, "vaccine_init", exp_len = 1)
  .validate_character(vaccine_end, "vaccine_end", exp_len = 1)
  .validate_geo_level(geo_level)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_logical(fix_residence, "fix_residence")
  .validate_vaccines(c(vaccine_init, vaccine_end), data.EIR, "data.EIR")
  .validate_date(data.EIR$date_birth, "date_birth")

  # Checks if the birth_cohorts variable is used
  if (!is.null(birth_cohorts)) {
    data.EIR <- data.EIR %>%
      filter(year(date_birth) %in% birth_cohorts)
  }

  # When at a level greater than ADM0, each person should be assigned to a single residence
  if(geo_level != "ADM0") {
    # NOTE: this function will stop execution when fix_residence is FALSE and the
    #       data frame contains more than one residence per person
    data.EIR <- .enforce_single_residence(data.EIR, fix_residence)
  }

  # Keeps the residence columns for the admin level used, renamed to ADM1 and ADM2 as in other modules
  geo_cols <- .geo_level_cols(geo_level)
  data.EIR <- data.EIR %>%
    rename(ADM1 = ADM1_residence, ADM2 = ADM2_residence) %>%
    select(ID, dose, date_vax, all_of(geo_cols))

  # Validates for duplicates in data, warning message only
  .validate_duplicates(data.EIR, vaccine_init, vaccine_end)

  data.EIR <- data.EIR %>%
    filter(dose == vaccine_init | dose == vaccine_end) %>%
    mutate(dose = ifelse(dose == vaccine_init, "vaccine_init", "vaccine_end"))

  data.EIR <- data.EIR %>%
    mutate(dose = factor(dose, levels = c("vaccine_init","vaccine_end"))) %>%
    arrange(dose) %>%
    pivot_wider(names_from = dose, values_from = date_vax, values_fn = {function(x){return(TRUE)}}) %>%
    filter(!is.na(vaccine_init)) %>%
    mutate(dropout = case_when(
      is.na(vaccine_end) ~ "dropout",
      TRUE ~ "complete"
    ))


  dropout_rate_nominal <- data.EIR %>%
    group_by(across(all_of(c(geo_cols, "dropout")))) %>%
    summarise(num = n()) %>%
    mutate(denom = sum(num),
           percent = num / denom * 100)

  # NOTE: the residence columns keep their original names in the output, for compatibility
  dropout_rate_nominal <- dropout_rate_nominal %>%
    rename(indicator = dropout) %>%
    rename(any_of(c(ADM1_residence = "ADM1", ADM2_residence = "ADM2")))

  return(dropout_rate_nominal)
}
