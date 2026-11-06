#' (D)uplicate (D)oses Trend
#'
#' This function calculates the percentage of duplicate records in the electronic immunization registry (EIR) according to their reported month of vaccination, further disaggregating by geographic level. It essentially performs the same calculation as \code{dd_rate}, but disaggregates by time in order to spot any possible trends. Repeated records are not included: to explore them, use \code{dd_repeat_plot}.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all doses in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame with one row for each group, with the same columns as \code{dd_rate}, plus \code{month_vax}, the first day of the month of vaccination. The \code{duplication} column is always \code{DUPLICATE}, and is kept so the output has the same structure as \code{dd_rate}.
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
dd_trend <- function(data.EIR, geo_level = "ADM0", vaccines = NULL, birth_cohorts = NULL) {

  # validations
  .validate_data.EIR(data.EIR, required_columns = .dd_required_cols)
  .validate_geo_level(geo_level)
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  # filter and classify each record according to the duplication categories
  classified <- .dd_prepare(data.EIR, vaccines, birth_cohorts) %>%
    # first day of the month of vaccination of each record
    mutate(month_vax = floor_date(date_vax, "month"))

  # Calculates the rates for geo_level and each month, keeping only the duplicates
  dd_trend <- .dd_summarise(classified, c(.geo_level_cols(geo_level), "month_vax")) %>%
    filter(duplication == "DUPLICATE")

  # Returns summary table
  return(dd_trend)
}
