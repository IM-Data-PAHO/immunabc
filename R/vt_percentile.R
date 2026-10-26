#' (V)accination (T)imeliness Percentiles
#'
#' This function calculates the number of days since the start of the timeliness window needed to vaccinate a given percentage of the analyzed records, for each \code{dose} and geographic area present in \code{data}.
#'
#' @param data The output from the \code{immunabc::vt_distribution} function. The disaggregation is inherited from this data.
#' @param percentiles Numeric. A vector of percentiles (greater than 0 and at most 100) to calculate. Default is \code{c(25, 50, 75)}.
#'
#' @return A data frame with one row per \code{percentile} for each \code{dose} and geographic area, with the following columns:
#' \itemize{
#'   \item \code{percentile}: the percentile.
#'   \item \code{day}: first day since the start of the timeliness window at which the cumulative percentage vaccinated (\code{cdf}) reaches the percentile.
#'   \item \code{age}: age in days at which the percentile is reached (\code{day + age_schedule_low}).
#'   \item \code{within_window}: whether \code{day} falls within the timeliness window for that dose.
#'   \item \code{window_end}: last timely day for that dose.
#'   \item \code{total}: number of vaccinations in the EIR for that \code{dose} and geographic area, excluding those vaccinated before the timeliness window and those with a missing date.
#' }
#' It can be passed to \code{vt_percentile_plot}.
#'
#' @import dplyr
#' @import tidyr
#'
#' @export
vt_percentile <- function(data, percentiles = c(25, 50, 75)) {

  # validations
  .validate_vt_distribution_data(data)
  .validate_percentiles(percentiles, "percentiles", min_len = 1)

  # Detects the group columns produced by vt_distribution
  group_cols <- intersect(c("dose", "ADM1", "ADM2"), names(data))

  vt_percentile <- data %>%
    # make one copy of the data for each percentile
    expand_grid(percentile = percentiles) %>%
    # Keeps the days where the percentile has been reached
    # NOTE: tolerance avoids floating point issues (e.g. 75 vs 74.99999)
    filter(cdf >= percentile - 1e-9) %>%
    group_by(across(all_of(c(group_cols, "percentile", "total", "window_end")))) %>%
    # First day at which the percentile is reached
    summarise(day = min(day), age = min(age), .groups = "drop") %>%
    mutate(within_window = day <= window_end) %>%
    select(all_of(group_cols), percentile, day, age, within_window, window_end, total) %>%
    arrange(across(all_of(c(group_cols, "percentile"))))

  return(vt_percentile)
}
