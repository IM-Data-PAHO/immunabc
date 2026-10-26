#' (E)ligibility (C)onsistency (C)omparison Barplot
#'
#' NOTE: Not exported. The eligibility criteria are currently being redefined, so this function should not be used for the time being.
#'
#' Generates a bar plot of eligibility rates (doses administered within vs outside the scheduled age window), grouped by geographic area and colored by eligibility result. If \code{data} is disaggregated by \code{dose} (i.e. \code{ecc_rate} was run with \code{vaccines} specified), the plot is faceted by dose.
#'
#' @param data The output from the \code{immunabc::ecc_rate} function.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param plot_missing Boolean (default TRUE). Plots DATE_MISSING records as its own category. Defaults to TRUE so all bars add to 100.
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @keywords internal
#' @noRd
ecc_barplot <- function(data, within_ADM1 = NULL, plot_missing = TRUE) {

  .validate_ecc_barplot_data(data)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)

  # detect geo level
  ADM_detected <- .detect_geo_level(data)

  # detect if data is disaggregated by dose
  has_dose <- "dose" %in% names(data)

  # prepare data for plot
  prepare_data <- data %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  # Extract number of missing values for caption
  n_missing <- prepare_data %>%
    filter(eligibility == "DATE_MISSING") %>%
    ungroup() %>%
    summarise(n = sum(n)) %>%
    pull(n)

  prepare_data <- prepare_data %>%
    mutate(eligibility = factor(eligibility, levels = c("DATE_MISSING", "INELIGIBLE", "ELIGIBLE"))) %>%
    filter(if(plot_missing == FALSE){eligibility != "DATE_MISSING"} else {TRUE})

  # do plot
  if(ADM_detected == 0) {
    p <- ggplot(prepare_data, aes(x = "ADM0", y = rate, fill = eligibility))
  } else {
    p <- ggplot(
      prepare_data,
      aes(
        x = factor(
          !!sym(paste0("ADM", ADM_detected)),
          levels = sort(unique(prepare_data[[paste0("ADM", ADM_detected)]]))
        ),
        y = rate, fill = eligibility)
    )
  }

  p <- p + geom_col(position = "stack") +
    labs(
      title = "Eligibility consistency comparison",
      subtitle = "Age at vaccination vs scheduled age window",
      x = "Geographic Area",
      y = "Rate (%)",
      caption = paste0("Number of records with at least one date missing: ", n_missing)
    ) +
    scale_y_continuous(limits = c(0, 100.9), n.breaks = 5) +
    scale_fill_manual(values = c("ELIGIBLE" = "#9cdbf4", "INELIGIBLE" = "#fabf7b", "DATE_MISSING" = "#838383")) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank(),
      panel.border = element_rect(fill = NA)
    )

  if(has_dose) {
    p <- p + facet_wrap(~dose)
  }

  return(p)
}
