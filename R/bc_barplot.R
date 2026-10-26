#' (B)irth (C)ohort Coverage Bar Plot
#'
#' Generates a bar plot of birth cohort coverage, grouped by geographic area and colored by birth cohort year.
#'
#' @param data Data frame. The output from the \code{immunabc::bc_coverage} function.
#' @param vaccine Character. A string specifying the vaccine of interest. Only one vaccine.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which coverage should be plotted. If \code{NULL} (default), all years are plotted.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param palette Character (optional). A RColorBrewer palette name for the cohort colors. Default is \code{"YlOrBr"}.
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
bc_barplot <- function(data, vaccine, birth_cohorts = NULL, within_ADM1 = NULL, palette = "YlOrBr") {

  .validate_bc_barplot_data(data)
  .validate_character(vaccine, "vaccine", exp_len = 1)
  .validate_vaccines(vaccine, data, "data")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_character(palette, "palette", exp_len = 1)

  # detect geo level
  ADM_detected <- .detect_geo_level(data)
  geo_column <- paste0("ADM", ADM_detected)

  # prepare data for plot
  prepare_data <- data %>%
    filter(dose == vaccine) %>%
    filter(if(!is.null(birth_cohorts)) {year_cohort %in% birth_cohorts} else {TRUE}) %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  cohort_levels <- prepare_data %>%
    pull(year_cohort) %>%
    unique() %>%
    sort()

  if(length(cohort_levels) > 9) {
    cohort_levels <- tail(cohort_levels, 9)
    prepare_data <- prepare_data %>%
      filter(year_cohort %in% cohort_levels)
    warning("Data has more than 9 birth cohorts; keeping only the 9 latest cohorts for plotting.")
  }

  prepare_data <- prepare_data %>%
    mutate(year_cohort = factor(year_cohort, levels = cohort_levels))

  # get max coverage in data
  coverage_max <- max(prepare_data$coverage, na.rm = TRUE)
  coverage_max <- ceiling(coverage_max * 10) / 10 # round to tenth above
  coverage_max <- max(100, coverage_max) # make sure its always at least 100

  # do plot
  if(ADM_detected == 0) {
    p <- ggplot(prepare_data, aes(x = "ADM0", y = coverage, fill = year_cohort))
  } else {
    p <- ggplot(
      prepare_data,
      aes(x = reorder(!!sym(geo_column), -coverage), y = coverage, fill = year_cohort)
    )
  }

  p <- p +
    geom_col(position = "dodge") +
    labs(
      title = paste0("Birth Cohort Coverage, ", vaccine),
      x = "Geographic Area",
      y = "Coverage (%)"
    ) +
    scale_y_continuous(breaks = seq(0, coverage_max, 25), limits = c(0, coverage_max)) +
    scale_fill_brewer(palette = palette) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank()
    )

  return(p)
}
