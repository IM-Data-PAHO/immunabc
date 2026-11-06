#' (D)uplicate (D)oses Heatmap
#'
#' Generates a heatmap of duplicate (or repeated) records from the output of \code{dd_rate}. The heatmap naturally combines two variables, so it can be used to visualize the data for each geographic area and one of the other disaggregation variables: vaccines or birth cohorts. \code{data} must therefore come from \code{dd_rate} with a \code{geo_level} of "ADM1" or "ADM2" and a value for \code{disaggregate_by}.
#'
#' @param data The output from the \code{immunabc::dd_rate} function.
#' @param value Character. What to show in the cells: "rate" (default), the percentage of records in the \code{duplication} category, which shows where the problem is proportionally worst; or "n", the total number, which shows where most records need correcting.
#' @param duplication Character. Which records to show: "duplicate" (default), the extra records with the same person, dose, vaccination date and place of occurrence as an earlier record; or "repeated", the extra records with the same person and dose but a different date or place.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param min_total Numeric (optional). Minimum number of records for a cell to be filled, since rates based on few records can be misleading. Other cells are grey and blank. Default is \code{NULL}, which fills all cells.
#' @param digits The number of digits to show in the cells when \code{value} is "rate". Default is 1.
#' @param show_numbers Logical. Whether to show the number in each cell (TRUE, default) or a color legend instead (FALSE). Use when there are too many cells to read their numbers (e.g. at the "ADM2" level).
#'
#' @return A ggplot object representing the heatmap.
#'
#' @import dplyr
#' @import tidyr
#' @import ggplot2
#'
#' @export
dd_heatmap <- function(data, value = "rate", duplication = "duplicate", within_ADM1 = NULL, min_total = NULL, digits = 1, show_numbers = TRUE) {

  # validations
  .validate_dd_plot_data(data, "dd_rate")
  .validate_dd_value(value)
  .validate_dd_duplication(duplication)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(min_total, "min_total", exp_len = 1)
  .validate_numeric(digits, "digits", exp_len = 1)
  .validate_logical(show_numbers, "show_numbers")

  # prepare data for plot
  plot_data <- .dd_plot_data(data, duplication, value, within_ADM1)
  geo_col <- plot_data$geo_col
  disagg_col <- plot_data$disagg_col

  # stop if we do not have enough disaggregation levels to show in the heatmap
  if(length(geo_col) == 0 || length(disagg_col) == 0) {
    stop("Error: dd_heatmap needs data with two disaggregation levels: geo_level at either ADM1 or ADM2, as well as a value for the disaggregate_by argument.")
  }

  prepare_data <- plot_data$data %>%
    mutate(
      # the ADM1 or ADM2 column, merged under one name
      area = .data[[geo_col]],
      disagg_value = as.character(.data[[disagg_col]]),
      # rate or n as numeric
      cell_value = as.numeric(.data[[value]]),
      # blank out cells with fewer than min_total records
      cell_value = if(!is.null(min_total)) if_else(total >= min_total, cell_value, NA_real_) else cell_value
    )

  prepare_data <- prepare_data %>%
    select(area, disagg_value, cell_value) %>%
    # combinations with no records are shown as empty cells
    complete(area, disagg_value) %>%
    mutate(
      # compute text color dynamically: dark text on light background, light text on dark background
      text_color = ifelse(cell_value > max(cell_value, na.rm = TRUE) * 0.6, "white", "black"),
      label = case_when(
        is.na(cell_value) ~ "",
        value == "rate" ~ paste0(round(cell_value, digits), "%"),
        TRUE ~ as.character(cell_value)
      )
    )

  # areas go on the x-axis, as in the other heatmaps of the package, and the other disaggregation
  # on the y-axis, reversed so it reads from top to bottom
  prepare_data <- prepare_data %>%
    mutate(x_value = area, y_value = factor(disagg_value, levels = rev(sort(unique(disagg_value)))))
  disagg_label <- c(dose = "Vaccine", birth_cohort = "Birth cohort")[[disagg_col]]

  caption <- paste0("Grey cells: ", if(!is.null(min_total)) paste0("fewer than ", min_total, " records.") else "no records.")

  # do plot
  p <- ggplot(prepare_data, aes(x = x_value, y = y_value, fill = cell_value)) +
    geom_tile(color = "gray")

  if(show_numbers) {
    p <- p + geom_text(aes(label = label, colour = text_color), size = 3.5)
  }

  p <- p +
    labs(
      title = plot_data$title,
      subtitle = plot_data$subtitle,
      x = "Place of occurrence",
      y = disagg_label,
      fill = plot_data$axis_label,
      caption = caption
    ) +
    # gradient goes up to the highest value shown
    scale_fill_gradient(
      low = "white",
      high = "#173052",
      limits = c(0, NA),
      na.value = "grey85"
    ) +
    scale_colour_identity() +
    theme_classic() +
    theme(
      # the legend is only needed when the cells have no numbers
      legend.position = if(show_numbers) "none" else "right",
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    )

  return(p)
}
