#' (D)uplicate (D)oses Barplot
#'
#' Generates a bar plot of duplicate (or repeated) records from the output of \code{dd_rate}, showing either their percentage or their number. The disaggregations are detected from \code{data}: geographic areas go on the x-axis if present, otherwise doses or birth cohorts, and \code{dose} or \code{birth_cohort} become panels when \code{data} also has geographic areas.
#'
#' The y-axis is scaled to the data instead of 0 to 100, since duplicate records are usually a small percentage of all records. When showing rates, a dashed line shows the rate of all groups combined.
#'
#' @param data The output from the \code{immunabc::dd_rate} function.
#' @param value Character. What to show on the y-axis: "rate" (default), the percentage of records in the \code{duplication} category, which shows where the problem is proportionally worst; or "n", their number, which shows where most records need correcting.
#' @param duplication Character. Which records to show: "duplicate" (default), the extra records with the same person, dose, vaccination date and place of occurrence as an earlier record, which is the indicator; or "repeated", the extra records with the same person and dose but a different date or place.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param min_total Numeric (optional). Minimum number of records for a bar to be shown, since rates based on few records can be misleading. Hidden bars still count towards the dashed line. Default is \code{NULL}, which shows all bars.
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
dd_barplot <- function(data, value = "rate", duplication = "duplicate", within_ADM1 = NULL, min_total = NULL) {

  # validations
  .validate_dd_plot_data(data, "dd_rate")
  .validate_dd_value(value)
  .validate_dd_duplication(duplication)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(min_total, "min_total", exp_len = 1)

  # prepare data for plot
  plot_data <- .dd_plot_data(data, duplication, value, within_ADM1)
  geo_col <- plot_data$geo_col
  disagg_col <- plot_data$disagg_col

  # geographic areas go on the x-axis, if not the other disaggregation does
  x_col <- if(length(geo_col) > 0) geo_col else disagg_col
  panel_col <- if(length(geo_col) > 0) disagg_col else character(0)

  # grab the prepared data
  prepare_data <- plot_data$data

  # total for all groups combined
  combined <- prepare_data %>%
    group_by(across(all_of(panel_col))) %>%
    summarise(combined_rate = sum(n) / sum(total) * 100, .groups = "drop")

  # filter out certain columns if they do not meet the min_total
  if(!is.null(min_total)) {
    prepare_data <- prepare_data %>%
      filter(total >= min_total)

    if(nrow(prepare_data) == 0) {
      stop("Error: No bars left to plot with the specified min_total.")
    }
  }

  # sort bars for each disaggregation type
  x_levels <- if(length(x_col) == 0) {
      "ADM0"
    } else if(x_col == "birth_cohort" || length(panel_col) > 0) {
      # order x axis alphabetically when using facets, or order the birth
      # cohorts chronologically on the x axis
      sort(unique(prepare_data[[x_col]]))
    } else {
      prepare_data %>% arrange(desc(.data[[value]])) %>% pull(all_of(x_col))
    }

  prepare_data <- prepare_data %>%
    mutate(
      x_value = if(length(x_col) == 0) "ADM0" else as.character(.data[[x_col]]),
      x_value = factor(x_value, levels = as.character(x_levels))
    )

  # do plot
  p <- ggplot(prepare_data, aes(x = x_value, y = .data[[value]])) +
    # orange for duplicates, purple for repeats, so the two are not confused
    geom_col(fill = if(duplication == "duplicate") "#fabf7b" else "#c9a3dd")

  # grab the subtitle
  subtitle <- plot_data$subtitle
  
  # only show a combined dashed line when plotting the rate (and as long as there is more than 1 bar)
  show_combined <- value == "rate" && n_distinct(prepare_data$x_value) > 1
  if(show_combined) {
    p <- p + geom_hline(
      data = combined,
      aes(yintercept = combined_rate),
      linetype = "dashed", color = "#173052"
    )

    subtitle <- paste0(subtitle, ". Dashed line: all groups combined")
  }

  # facets
  if(length(panel_col) > 0) {
    p <- p + facet_wrap(vars(!!sym(panel_col)))
  }

  # label the x axis depending on the data disaggregation
  x_label <- if(length(geo_col) > 0) {
      "Place of occurrence"
    } else if(identical(disagg_col, "dose")) {
      "Vaccine"
    } else if(identical(disagg_col, "birth_cohort")) {
      "Birth cohort"
    } else {
      NULL
    }

  # add a caption when min_total is used
  caption <- plot_data$caption
  if(!is.null(min_total)) {
    caption <- paste0(caption, "\nGroups with fewer than ", min_total, " records are not shown.")
  }

  # final touches
  p <- p +
    labs(
      title = plot_data$title,
      subtitle = subtitle,
      x = x_label,
      y = plot_data$axis_label,
      caption = caption
    ) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      panel.border = element_rect(fill = NA)
    )

  return(p)
}
