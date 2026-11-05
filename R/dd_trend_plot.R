#' (D)uplicate (D)oses Trend Plot
#'
#' Generates a line plot of the percentage or number of duplicate (or repeated) records according to their reported vaccination date, from the output of \code{dd_trend}, which helps identify the vaccination periods most affected. If duplicates are high only for a few periods, the records from those periods may have been entered twice, for example when moving data from an old system into the EIR.
#'
#' If \code{data} is disaggregated by geographic area, each area is drawn as a thin grey line for context, and all areas combined are drawn as a single highlighted line. Specific areas can be highlighted in color with \code{highlight}. To show a single vaccine, use the \code{vaccines} argument of \code{dd_rate}.
#'
#' @param data The output from the \code{immunabc::dd_trend} function.
#' @param value Character. What to show on the y-axis: "rate" (default), the percentage of records in the \code{duplication} category; or "n", their number. With "n", all areas combined will show the sum of all areas, so its value may be significantly larger than each individual area.
#' @param duplication Character. Which records to show: "duplicate" (default), the extra records with the same person, dose, vaccination date and place of occurrence as an earlier record; or "repeated", the extra records with the same person and dose but a different date or place.
#' @param highlight Character (optional). Up to 5 geographic areas to highlight in color. Only available when \code{data} is disaggregated by "ADM1" or "ADM2". Default is \code{NULL}, which highlights nothing.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. All areas combined then refers to those areas only. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param min_total Numeric (optional). Minimum number of records required for a line to be shown for a given period. This means each line may have gaps if the number of records was too small at a given point in time. This is useful because rates based on few records can be misleading and stretch the y-axis. Default is \code{NULL}, which shows all periods.
#'
#' @return A ggplot object representing the trend plot.
#'
#' @import dplyr
#' @import tidyr
#' @import ggplot2
#' @import lubridate
#'
#' @export
dd_trend_plot <- function(data, value = "rate", duplication = "duplicate", highlight = NULL, within_ADM1 = NULL, min_total = NULL) {

  # validations
  .validate_dd_plot_data(data, "dd_trend")
  .validate_dd_value(value)
  .validate_dd_duplication(duplication)
  .validate_character(highlight, "highlight", min_len = 1, max_len = 5)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(min_total, "min_total", exp_len = 1)

  # prepare data for plot
  plot_data <- .dd_plot_data(data, duplication, value, within_ADM1, trend = TRUE)
  geo_col <- plot_data$geo_col
  time_col <- plot_data$time_col
  subnational_detected <- length(geo_col) > 0

  # the first day of each period, whether weeks, months, quarters or years
  prepare_data <- plot_data$data %>%
    mutate(period = .data[[time_col]])

  # check that the areas to highlight exist
  if(!is.null(highlight)) {
    if(!subnational_detected) {
      stop("Error: highlight is only available when data is disaggregated by ADM1 or ADM2.")
    }
    missing_areas <- setdiff(highlight, prepare_data[[geo_col]])
    if(length(missing_areas) > 0) {
      stop(paste0("Error: The following areas in highlight are not in data: ", paste(missing_areas, collapse = ", "), "."))
    }
  }

  # Sum together all areas in the data, calculated from the counts so all records weigh the same
  combined_label <- if(subnational_detected) "All areas combined" else "ADM0"
  combined_data <- prepare_data %>%
    group_by(period) %>%
    summarise(rate = sum(n) / sum(total) * 100, n = sum(n), .groups = "drop") %>%
    mutate(series = combined_label, line_value = as.numeric(.data[[value]])) %>%
    select(series, period, line_value)

  # colors for each line including the combined line and the highlights
  series_levels <- c(combined_label, highlight)
  series_colors <- setNames(
    c("#2E9FDF", "#E66100", "#5D3A9B", "#1B9E77", "#D41159", "#8C510A")[seq_along(series_levels)],
    series_levels
  )

  p <- ggplot()

  highlight_data <- NULL
  if(subnational_detected) {
    # months with no records or too few records appear as gaps
    area_data <- prepare_data %>%
      mutate(
        series = .data[[geo_col]],
        # pick the value, either the rate or the n
        line_value = as.numeric(.data[[value]]),
        # remove values for periods when we dont have enough observations
        line_value = if(!is.null(min_total)) if_else(total >= min_total, line_value, NA_real_) else line_value
      ) %>%
      select(series, period, line_value) %>%
      complete(series, period)

    highlight_data <- area_data %>%
      filter(series %in% highlight)

    # each geographic area as a thin grey line, with its own entry in the legend
    area_label <- paste0("Other ", geo_col, " areas")
    series_colors <- c(series_colors, setNames("grey80", area_label))
    p <- p + geom_line(
      data = area_data,
      aes(x = period, y = line_value, group = series, color = !!area_label),
      linewidth = 0.3, na.rm = TRUE
    )
  }

  # combined and highlights
  series_data <- bind_rows(combined_data, highlight_data) %>%
    mutate(series = factor(series, levels = series_levels))

  caption <- plot_data$caption
  if(!is.null(min_total)) {
    caption <- paste0(caption, "\nPeriods of an area with fewer than ", min_total, " records are not shown.")
  }

  # handles the different x axis label and ticks depending on the period in the data, for readability
  x_label <- c(
    week_vax = "Week of vaccination", month_vax = "Month of vaccination",
    quarter_vax = "Quarter of vaccination", year_vax = "Year of vaccination"
  )[[time_col]]
  date_labels <- switch(time_col,
    week_vax = function(x) format(x, "%Y-%m-%d"),
    month_vax = function(x) format(x, "%Y-%m"),
    quarter_vax = function(x) paste0(year(x), " Q", quarter(x)),
    year_vax = function(x) format(x, "%Y")
  )
  # quarters and years get one tick each, since automatic ticks can fall in the middle of a period
  date_breaks <- if(time_col %in% c("quarter_vax", "year_vax")) sort(unique(prepare_data$period)) else waiver()

  # do plot
  p <- p +
    geom_line(
      data = series_data,
      aes(x = period, y = line_value, color = series),
      linewidth = 0.9, na.rm = TRUE
    ) +
    labs(
      title = paste0(plot_data$title, " over time"),
      x = x_label,
      y = plot_data$axis_label,
      caption = caption
    ) +
    scale_x_date(breaks = date_breaks, labels = date_labels) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
    # NOTE: without separate subnational areas, the only series is ADM0, so hide the legend in that case
    scale_color_manual(
      values = series_colors,
      # legend order: all areas combined, the highlighted areas and then the grey lines
      breaks = names(series_colors),
      drop = FALSE
    ) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank(),
      panel.border = element_rect(fill = NA)
    )

  return(p)
}
