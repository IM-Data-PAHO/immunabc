#' (V)accination (T)imeliness Cumulative Distribution Plot
#'
#' Generates a plot of the cumulative percentage vaccinated since the start of the timeliness window, faceted by \code{dose}.
#'
#' The timeliness window of each dose is shaded. If \code{data} is disaggregated by geographic area, each area is drawn as a thin grey line for context, and all areas combined are drawn as a single highlighted line. Specific areas can be highlighted in color with \code{highlight}. Records vaccinated before the timeliness window and records with a missing date are excluded from the distribution and reported in the caption.
#'
#' @param data The output from the \code{immunabc::vt_distribution} function.
#' @param percentile Numeric (optional). A single percentile (greater than 0 and at most 100) to highlight in the plot. This is inserted as a label for all highlighted areas and for the combined plot. Default is \code{NULL}, which highlights nothing.
#' @param highlight Character (optional). Up to 5 geographic areas to highlight in color. Only available when \code{data} is disaggregated by "ADM1" or "ADM2". Default is \code{NULL}, which highlights nothing.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param max_days Numeric (optional). Maximum number of days since the start of the timeliness window to show on the x-axis, useful to trim long tails of late vaccinations. Default is \code{NULL}, which shows up to the day at which 95\% of records are vaccinated.
#' @param x_axis Character. Either "absolute" (default), where the x-axis shows the age at vaccination in days, starting at the \code{age_schedule_low} of each dose; or "relative", where the x-axis shows the days since the start of the timeliness window, starting at 0 for every dose.
#'
#' @return A ggplot object representing the cumulative distribution plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
vt_cdf_plot <- function(data, percentile = NULL, highlight = NULL, within_ADM1 = NULL, max_days = NULL, x_axis = "absolute") {

  # validations
  .validate_vt_distribution_data(data)
  .validate_percentiles(percentile, "percentile", exp_len = 1)
  .validate_character(highlight, "highlight", min_len = 1, max_len = 5)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(max_days, "max_days", exp_len = 1)
  if(!is.null(max_days) && max_days <= 0) {
    stop("Error: max_days should be greater than 0.")
  }
  .validate_x_axis(x_axis)

  # prepare data for plot
  plot_data <- .vt_distribution_plot_data(data, percentile, highlight, within_ADM1, max_days)
  max_days <- plot_data$max_days

  # column used for the x-axis: age at vaccination (absolute) or days since the start of the timeliness window (relative)
  x_col <- if(x_axis == "absolute") "age" else "day"

  # get the min and max values for the timeliness windows
  window_data <- plot_data$window_data %>%
    mutate(
      xmin = if(x_axis == "absolute") age_schedule_low else 0,
      xmax = xmin + pmin(window_end, max_days)
    )

  # shade the timeliness window of each dose (cut at max_days)
  p <- ggplot() +
    geom_rect(
      data = window_data,
      aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = "Timeliness window"),
      alpha = 0.4
    ) +
    scale_fill_manual(values = c("Timeliness window" = "#9cdbf4"))

  # each geographic area as a thin grey line, for context
  if(plot_data$subnational_detected) {
    p <- p + geom_step(
      data = plot_data$area_data %>% filter(day <= max_days),
      aes(x = !!sym(x_col), y = cdf, group = series),
      color = "grey80", linewidth = 0.3
    )
  }

  # colored series: all subnational areas combined + highlighted areas
  p <- p + geom_step(
    data = plot_data$series_data %>% filter(day <= max_days),
    aes(x = !!sym(x_col), y = cdf, color = series),
    linewidth = 0.9
  )

  # highlight the days needed to reach the percentile
  if(!is.null(percentile)) {
    # takes care of drawing labels for each percentile of each of the colored
    # series in the plot. draws from top to bottom so they do not overlap
    percentile_data <- plot_data$percentile_data %>%
      filter(day <= max_days) %>%
      group_by(dose) %>%
      mutate(
        rank = rank(day, ties.method = "first"),
        step = min(8, percentile / (n() + 1))
      ) %>%
      ungroup() %>%
      mutate(
        label_y = percentile - rank * step,
        label = paste0("P", percentile, ": ", .data[[x_col]], ifelse(.data[[x_col]] == 1, " day", " days"))
      )
    p <- p +
      geom_hline(yintercept = percentile, linetype = "dashed", color = "grey40") +
      # segment from the percentile down to 0
      geom_segment(
        data = percentile_data,
        aes(x = !!sym(x_col), xend = !!sym(x_col), y = percentile, yend = 0, color = series),
        linetype = "dotted"
      ) +
      geom_label(
        data = percentile_data,
        aes(x = !!sym(x_col), y = label_y, label = label, color = series),
        hjust = -0.05, vjust = 0.5,
        size = 3, show.legend = FALSE
      )
  }

  p <- p +
    scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.02))) +
    # NOTE: without separate subnational areas, the only series is ADM0, so hide the legend in that case
    scale_color_manual(values = plot_data$series_colors, drop = FALSE, guide = if(plot_data$subnational_detected) "legend" else "none") +
    labs(
      title = if(x_axis == "absolute") "Cumulative vaccination by age" else "Cumulative vaccination by days since the start of the timeliness window",
      subtitle = plot_data$subtitle,
      x = if(x_axis == "absolute") "Age at vaccination (days)" else "Days since the start of the timeliness window",
      y = "Cumulative % vaccinated",
      caption = plot_data$caption
    ) +
    theme_classic() +
    theme(
      legend.title = element_blank(),
      legend.position = "right",
      panel.border = element_rect(fill = NA)
    ) +
    # NOTE: in the absolute x-axis each dose starts at a different age, so each facet has its own x-axis
    facet_wrap(~ dose, scales = if(x_axis == "absolute") "free_x" else "fixed")

  return(p)
}
