#' Dose (S)equence (C)omparison Inconsistent Records Plot
#'
#' Generates a heatmap showing how inconsistent dose sequences (sequences where an earlier dose is skipped) are distributed across the combinations of doses received, for each geographic area of residence. Each column adds to 100\% of the inconsistent sequences in that area. Consistent sequences are not shown.
#'
#' @param data The output from the \code{immunabc::sc_inconsistent} function.
#' @param geo_level Character. The geographic level of residence to show as columns. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param digits The number of digits to show in the labels. Default is 0.
#'
#' @return A ggplot object representing the heatmap.
#'
#' @import dplyr
#' @import tidyr
#' @import ggplot2
#' @import stringr
#'
#' @export
sc_inconsistent_plot <- function(data, geo_level = "ADM0", within_ADM1 = NULL, digits = 0) {

  .validate_sc_inconsistent_data(data)
  .validate_geo_level(geo_level)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(digits, "digits", exp_len = 1)

  # prepare data for plot
  prepare_data <- data %>%
    rename(ADM1 = ADM1_residence, ADM2 = ADM2_residence) %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE}) %>%
    mutate(ADM0 = "ADM0")

  # most frequent combinations of doses received at the top
  sequence_levels <- prepare_data %>%
    count(sequence) %>%
    arrange(n) %>%
    pull(sequence)

  # proportion of each combination of doses received within each area
  plot_data <- prepare_data %>%
    count(area = !!sym(geo_level), sequence) %>%
    complete(area, sequence, fill = list(n = 0)) %>%
    group_by(area) %>%
    mutate(proportion = round(n / sum(n) * 100, digits)) %>%
    ungroup() %>%
    mutate(
      sequence = factor(sequence, levels = sequence_levels),
      # compute text color dynamically: dark text on light background, light text on dark background
      text_color = ifelse(proportion > max(proportion) * 0.6, "white", "black"),
      label = if(geo_level == "ADM0") paste0(proportion, "%\n(n = ", n, ")") else paste0(proportion, "%")
    )

  # do plot
  p <- ggplot(plot_data, aes(x = area, y = sequence, fill = proportion)) +
    geom_tile(color = "gray") +
    geom_text(aes(label = label, colour = text_color), size = 4) +
    labs(
      title = "Inconsistent dose sequences",
      subtitle = "Percentage of inconsistent sequences in each area",
      x = "Residence",
      y = "Doses received",
      caption = paste0("Number of inconsistent sequences: ", nrow(prepare_data))
    ) +
    # gradient goes up to the highest proportion, since inconsistent sequences are split across several combinations
    scale_fill_gradient(
      low = "white",
      high = "#173052",
      limits = c(0, NA)
    ) +
    # one dose per line, since dose names can be long
    scale_y_discrete(labels = function(x) str_replace_all(x, fixed(" + "), " +\n")) +
    scale_colour_identity() +
    theme_classic() +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    )

  return(p)
}
