#' (V)accination (T)imeliness Percentile Plot
#'
#' Generates a range plot of the number of days since the start of the timeliness window needed to vaccinate each percentile, with one row per geographic area (or per dose, when \code{data} is not disaggregated by geographic area). Each percentile is drawn as a point, joined by a line from the lowest to the highest percentile. Rows are sorted by the percentile closest to the median (P50), with the slowest areas at the top, so the plot remains readable with many geographic areas. When \code{data} is disaggregated by geographic area, the plot is faceted by \code{dose}. The timeliness window of each dose is shaded.
#'
#' @param data The output from the \code{immunabc::vt_percentile} function.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param n_slowest Numeric (optional). Shows only this number of geographic areas, the ones that take the longest to reach the percentile closest to 50. Useful when there are many areas. Default is \code{NULL}, which shows all areas.
#'
#' @return A ggplot object representing the percentile plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
vt_percentile_plot <- function(data, within_ADM1 = NULL, n_slowest = NULL) {

  # validations
  .validate_vt_percentile_data(data)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(n_slowest, "n_slowest", exp_len = 1)
  if(!is.null(n_slowest) && n_slowest < 1) {
    stop("Error: n_slowest should be at least 1.")
  }

  # detect geo level
  ADM_detected <- .detect_geo_level(data)
  subnational_detected <- ADM_detected > 0
  geo_col <- if(subnational_detected) paste0("ADM", ADM_detected) else NULL

  # prepare data for plot: one row per geographic area, or per dose when there is no geographic area
  prepare_data <- data %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})
  prepare_data$row <- if(subnational_detected) prepare_data[[geo_col]] else prepare_data$dose

  # facet by dose only when rows are geographic areas
  facet_cols <- if(subnational_detected) "dose" else character(0)

  # sorting percentile: the one closest to the median (the lowest, in case of a tie)
  percentiles <- sort(unique(prepare_data$percentile))
  sort_percentile <- percentiles[which.min(abs(percentiles - 50))]

  # days to reach the sorting percentile per row
  # NOTE: averaged across doses when faceting
  row_order <- prepare_data %>%
    filter(percentile == sort_percentile) %>%
    group_by(row) %>%
    summarise(sort_day = mean(day), .groups = "drop") %>%
    arrange(sort_day)

  # keeps only the slowest areas
  n_rows <- nrow(row_order)
  if(!is.null(n_slowest) && n_slowest < n_rows) {
    row_order <- row_order %>% slice_tail(n = n_slowest)
    prepare_data <- prepare_data %>% filter(row %in% row_order$row)
  }

  # NOTE: the first level is drawn at the bottom, so the slowest rows end at the top
  prepare_data <- prepare_data %>%
    mutate(
      row = factor(row, levels = row_order$row),
      percentile = factor(paste0("P", percentile), levels = paste0("P", percentiles))
    )

  # line from the lowest to the highest percentile of each row
  range_data <- prepare_data %>%
    group_by(across(all_of(c(facet_cols, "row")))) %>%
    summarise(day_min = min(day), day_max = max(day), .groups = "drop")

  p <- ggplot()

  # shade the timeliness window of each dose
  window_data <- prepare_data %>%
    distinct(across(all_of(c(facet_cols, "row"))), window_end)
  p <- p + geom_tile(
    data = window_data,
    aes(x = window_end / 2, width = window_end, y = row, fill = "Timeliness window"),
    height = 0.8, alpha = 0.6
  ) +
    scale_fill_manual(values = c("Timeliness window" = "#9cdbf4"))

  # do plot
  p <- p +
    geom_segment(
      data = range_data,
      aes(x = day_min, xend = day_max, y = row, yend = row),
      color = "grey50", linewidth = 0.6
    ) +
    geom_point(data = prepare_data, aes(x = day, y = row, color = percentile), size = 2.5) +
    scale_color_viridis_d(begin = 0.1, end = 0.85, direction = -1) +
    scale_x_continuous(expand = expansion(mult = c(0.01, 0.05))) +
    labs(
      title = "Days needed to vaccinate each percentile",
      subtitle = paste0("Sorted by P", sort_percentile),
      x = "Days since the start of the timeliness window (age_schedule_low)",
      y = if(subnational_detected) geo_col else "Dose",
      caption = if(!is.null(n_slowest) && n_slowest < n_rows) paste0("Showing the ", n_slowest, " slowest of ", n_rows, " areas.") else NULL
    ) +
    theme_classic() +
    theme(
      legend.title = element_blank(),
      panel.border = element_rect(fill = NA),
      panel.grid.major.y = element_line(color = "grey92")
    )

  if(subnational_detected) {
    p <- p + facet_wrap(~ dose)
  }

  return(p)
}
