#' (V)accination (T)imeliness Barplot
#'
#' Generates a bar plot showing percentage of doses administered within, before or after the timeliness window, grouped by geographic area. If \code{vt_rate} was run with \code{vaccines} specified, the plot is faceted by dose.
#'
#' @param data The output from the \code{immunabc::vt_rate} function.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param plot_missing Boolean (default TRUE). Plots DATE_MISSING records as its own category. Defaults to TRUE so all bars add to 100.
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
vt_barplot <- function(data, within_ADM1 = NULL, plot_missing = TRUE) {

  .validate_vt_barplot_data(data)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_logical(plot_missing, "plot_missing")

  # detect geo level
  ADM_detected <- .detect_geo_level(data)

  # detect if data is disaggregated by dose
  dose_detected <- "dose" %in% names(data)

  # prepare data for plot
  prepare_data <- data %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  # Extract number of missing values for caption
  n_missing <- prepare_data %>%
    filter(timeliness == "DATE_MISSING") %>%
    ungroup() %>%
    summarise(n = sum(n)) %>%
    pull(n)

  prepare_data <- prepare_data %>%
    mutate(timeliness = factor(timeliness, levels = c("DATE_MISSING", "UNTIMELY_EARLY", "UNTIMELY_LATE", "TIMELY"))) %>%
    filter(if(plot_missing == FALSE){timeliness != "DATE_MISSING"} else {TRUE})

  # build base plot depending on geo_level
  if(ADM_detected == 0) {
    p <- ggplot(prepare_data, aes(x = "ADM0", y = rate, fill = timeliness))
  } else {
    p <- ggplot(prepare_data, aes(x = !!sym(paste0("ADM", ADM_detected)), y = rate, fill = timeliness))
  }

  # do plot
  p <- p + geom_col(position = "stack") +
    labs(
      title = "Vaccination timeliness",
      subtitle = "Age at vaccination vs scheduled timeliness window",
      x = "Geographic Area",
      y = "Rate (%)",
      caption = paste0("Number of records with at least one date missing: ", n_missing)
    ) +
    scale_y_continuous(limits = c(0, 100.9), n.breaks = 5) +
    scale_fill_manual(values = c("TIMELY" = "#9cdbf4", "UNTIMELY_LATE" = "#fabf7b", "UNTIMELY_EARLY" = "#c9a3dd", "DATE_MISSING" = "#838383")) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank(),
      panel.border = element_rect(fill = NA)
    )

  if(dose_detected) {
    p <- p + facet_wrap(~ dose)
  }

  return(p)
}
