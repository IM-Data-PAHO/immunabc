#' (R)esidence (Oc)currence Bar Plot
#'
#' This function creates a bar plot showing vaccination coverage by place of residence and place of vaccination occurrence.
#'
#' @param data The output from the \code{immunabc::roc_coverage()} function.
#' @param year A numeric value specifying the year of the data to be plotted. Only one year.
#' @param vaccine A string specifying the vaccine of interest. Only one vaccine.
#' @param within_ADM1 When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#' @import tidyr
#'
#' @export
roc_barplot <- function(data, year, vaccine, within_ADM1 = NULL) {

  .validate_roc_barplot_data(data)
  .validate_numeric(year, "year", exp_len = 1)
  .validate_character(vaccine, "vaccine", exp_len = 1)
  .validate_vaccines(vaccine, data, "data")
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)

  # detect geo level
  ADM_detected <- .detect_geo_level(data)
  geo_column <- paste0("ADM", ADM_detected)
  pivot_columns <- c("year")
  if(ADM_detected != 0) {
    pivot_columns <- c(pivot_columns, geo_column)
  }

  # prepare dataframe for plot
  to_plot_wide <- data %>%
    # filter for vaccine and year
    filter(dose == vaccine, .data$year == .env$year) %>%
    # filter for ADM1 if necessary
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE}) %>%
    # select columns of interest
    select(pivot_columns, coverage, coverage_type) %>%
    # make wide for plot
    pivot_wider(
      id_cols = pivot_columns,
      names_from = "coverage_type",
      values_from = "coverage"
    )

  # get max coverage in data
  coverage_max <- max(
    to_plot_wide$occurrence,
    to_plot_wide$residence,
    na.rm = TRUE
  )
  coverage_max <- max(100, coverage_max) # make sure its always at least 100

  # do plot
  if(ADM_detected == 0) {
    p <- ggplot(to_plot_wide, aes(x = "ADM0"))
  } else {
    p <- ggplot(
      to_plot_wide,
      aes(x = reorder(!!sym(geo_column), -occurrence))
    )
  }

  p <- p +
    labs(
      title = paste0("Coverage by Residence and Occurrence, ", year),
      x = "Geographic Area",
      y = "Coverage (%)"
    ) +
    geom_col(aes(y = occurrence, fill = "Occurrence"), position = "dodge") +
    geom_hline(yintercept = 100, linetype = 2, colour = "#b35806", linewidth = 1.5) +
    geom_point(aes(y = residence, shape = "Residence"), size = 5, fill = "#fc8d59") +
    scale_y_continuous(breaks = seq(0, coverage_max, 25), limits = c(0, coverage_max)) +
    scale_fill_manual(values = c("Occurrence" = "#fee090")) +
    scale_shape_manual(values = c("Residence" = 23)) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank()
    )

  return(p)
}
