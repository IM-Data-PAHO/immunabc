#' (D)uplicate (D)oses Trend
#'
#' This function calculates the percentage of duplicate and repeated records in the electronic immunization registry (EIR) according to their reported date of vaccination, further disaggregating by geographic level. It essentially performs the same calculation as \code{dd_rate}, but disaggregates by time in order to spot any possible trends.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param period Character. The period of time to group vaccination dates by: "week", "month" (default), "quarter" or "year". Longer periods have more records each, so their rates are less noisy, especially for small areas.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all doses in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame with one row for each \code{duplication} category in each group, with the same columns as \code{dd_rate}, plus a column with the first day of each period. This column is named differently depending on the period and will be one of: \code{week_vax} (weeks start on Monday), \code{month_vax}, \code{quarter_vax} or \code{year_vax}.
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
dd_trend <- function(data.EIR, geo_level = "ADM0", period = "month", vaccines = NULL, birth_cohorts = NULL) {

  # validations
  .validate_data.EIR(data.EIR, required_columns = .dd_required_cols)
  .validate_geo_level(geo_level)
  .validate_character(period, "period", exp_len = 1)
  if(is.null(period) || !(period %in% .dd_periods)) {
    stop(paste0("Error: The period parameter should be one of: ", paste(.dd_periods, collapse = ", "), "."))
  }
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  # column with the first day of each period, e.g. month_vax
  time_col <- paste0(period, "_vax")

  # filter and classify each record according to the duplication categories
  classified <- .dd_prepare(data.EIR, vaccines, birth_cohorts) %>%
    # first day of the period of each record (weeks start on Monday)
    mutate(!!time_col := floor_date(date_vax, period, week_start = 1))

  # Calculates the rates for geo_level and each period
  dd_trend <- .dd_summarise(classified, c(.geo_level_cols(geo_level), time_col))

  # Returns summary table
  return(dd_trend)
}
