#' (D)ate (C)onsistency (C)omparison Barplot
#'
#' Generates a bar plot of date consistencies, grouped by geographic area and colored by consistency result.
#'
#' @param data The output from the \code{immunabc::dcc_rate} function.
#' @param date_1_name Character. Label for the first date variable, used in the plot subtitle.
#' @param date_2_name Character. Label for the second date variable, used in the plot subtitle.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param plot_missing Boolean (default TRUE). Plots DATE_MISSING records as its own category. Defaults to TRUE so all bars add to 100
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
dcc_barplot <- function(data, date_1_name = "date 1", date_2_name = "date 2", within_ADM1 = NULL, plot_missing = TRUE) {

  .validate_dcc_barplot_data(data)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)

  # detect geo level
  ADM_detected <- .detect_geo_level(data)

  # prepare data for plot
  prepare_data <- data %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE}) 

  # Extract number of missing values for caption
  n_missing <- prepare_data %>%
    filter(consistency == "DATE_MISSING") %>%
    ungroup() %>%
    summarise(n = sum(n)) %>%
    pull(n)
    

  prepare_data <- prepare_data %>%  
    mutate(consistency = factor(consistency, levels = c("DATE_MISSING", "INCONSISTENT", "CONSISTENT"))) %>% 
    filter(if(plot_missing == FALSE){consistency != "DATE_MISSING"} else {TRUE})



  # do plot
  if(ADM_detected == 0) {
    p <- ggplot(prepare_data, aes(x = "ADM0", y = rate, fill = consistency))
  } else {
    p <- ggplot(
      prepare_data,
      aes(
        x = factor(
          !!sym(paste0("ADM", ADM_detected)),
          levels = sort(unique(prepare_data[[paste0("ADM", ADM_detected)]]))
        ),
        y = rate, fill = consistency)
    )
  }

  p <- p + geom_col(position = "stack") +
    labs(
      title = "Date consistency comparison",
      subtitle = paste0(date_1_name, " vs ", date_2_name),
      x = "Geographic Area",
      y = "Rate (%)",
      caption = paste0("Number of records with at least one date missing: ", n_missing)
    ) +
    scale_y_continuous(limits = c(0, 100.9),n.breaks = 5) +
    scale_fill_manual(values = c("CONSISTENT"="#9cdbf4", "INCONSISTENT" = "#fabf7b", "DATE_MISSING" = "#838383")) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank(),
      panel.border = element_rect(fill = NA)
    )

  return(p)
}
