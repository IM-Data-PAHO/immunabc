#' (C)omplete (S)chedule Coverage Bar Plot
#'
#' Generates a bar plot of complete schedule vaccination coverage, grouped by geographic area and colored by birth cohort.
#'
#' @param data The output from the \code{immunabc::cs_coverage} function.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which coverage should be plotted. If \code{NULL} (default), all years are plotted.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
cs_barplot <- function(data, birth_cohorts = NULL, within_ADM1 = NULL) {

  .validate_cs_barplot_data(data)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1, max_len = 9)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)

  # detect geo level
  ADM_detected <- .detect_geo_level(data)

  # prepare data for plot
  prepare_data <- data
  if(!is.null(birth_cohorts)) {
    prepare_data <- prepare_data %>% filter(year %in% birth_cohorts)
  }
  prepare_data <- prepare_data %>%
    mutate(year = factor(year)) %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  # do plot
  if(ADM_detected == 0) {
    p <- ggplot(prepare_data, aes(x = "ADM0", y = coverage, fill = year))
  } else {
    p <- ggplot(
      prepare_data,
      aes(
        x = reorder(!!sym(paste0("ADM", ADM_detected)), -coverage),
        y = coverage, fill = year)
    )
  }

  p <- p + geom_col(position = "dodge") +
    labs(
      title = "Complete Schedule Coverage",
      x = "Geographic Area",
      y = "Coverage (%)"
    ) +
    scale_y_continuous(limits = c(0, 100)) +
    scale_fill_brewer(palette = "Pastel1") +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank(),
      panel.border = element_rect(fill = NA)
    )

  return(p)
}
