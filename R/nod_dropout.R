#' (No)minal (D)ropout Rate
#'
#' @param data.EIR A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccine_init Initial vaccine to use in nominal dropout calculation.
#' @param vaccine_end Final vaccine to use in nominal dropout calculation.
#' @param geo_level The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param birth_cohorts Birth cohorts to calculate for. As a vector of years.
#' @param fix_residence Logical. When geo_level is "ADM1" or "ADM2" and a person's residence differs across their records, whether to correct all of that person's records to the residence of their most recent vaccination (TRUE, default) or leave the data as-is (FALSE), which may cause inaccurate dropout results.
#'
#' @return A data frame with the calculated coverage for the administrative level selected. Includes the nominal dropout rate, numerator, denominator and completeness rate. based on the administrative level, birth cohorts and vaccines selected.
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

  # Checks residence consistency per ID, since it affects pivoting at ADM1/ADM2 level
  if(geo_level != "ADM0") {
    n_inconsistent <- .validate_residence(data.EIR)

    if(fix_residence) {
      data.EIR <- .fix_residence(data.EIR)
    } else if(n_inconsistent > 0) {
      warning(
        "Residence inconsistencies were not corrected (fix_residence = FALSE). ",
        "Please resolve them manually before trusting nod_dropout results, or set fix_residence = TRUE."
      )
    }
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
