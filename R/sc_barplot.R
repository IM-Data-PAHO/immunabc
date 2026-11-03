#' Dose (S)equence (C)omparison Barplot
#'
#' Generates a stacked bar plot of dose sequences, grouped by geographic area. It accepts the output of either:
#' \itemize{
#'   \item \code{sc_rate}: shows consistent and inconsistent sequences (\code{mode = "simple"}) or consistent sequences and every inconsistent combination of doses received (\code{mode = "complex"}).
#'   \item \code{sc_date_sequence}: shows chronologically consistent and inconsistent sequences.
#' }
#'
#' @param data The output from the \code{immunabc::sc_rate} or \code{immunabc::sc_date_sequence} functions.
#' @param sequence_name Character. Label for the dose sequence, used in the plot subtitle (e.g. \code{"DTP1 - DTP3"}). Default is \code{"dose sequence"}.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param plot_missing Boolean (default TRUE). Only used with the output of \code{sc_date_sequence}. Plots DATE_MISSING sequences as its own category. Defaults to TRUE so all bars add to 100.
#'
#' @return A ggplot object representing the bar plot.
#'
#' @import dplyr
#' @import ggplot2
#' @import stringr
#'
#' @export
sc_barplot <- function(data, sequence_name = "dose sequence", within_ADM1 = NULL, plot_missing = TRUE) {

  .validate_sc_barplot_data(data)
  .validate_character(sequence_name, "sequence_name", exp_len = 1)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_logical(plot_missing, "plot_missing")

  # detect geo level
  ADM_detected <- .detect_geo_level(data)

  # detect if data comes from sc_date_sequence (chronology) or sc_rate (sequence)
  chronology_detected <- "chronology" %in% names(data)

  # prepare data for plot
  prepare_data <- data %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  caption <- NULL

  if(chronology_detected) {
    # Extract number of missing values for caption
    n_missing <- prepare_data %>%
      filter(chronology == "DATE_MISSING") %>%
      ungroup() %>%
      summarise(n = sum(n)) %>%
      pull(n)

    prepare_data <- prepare_data %>%
      mutate(category = factor(chronology, levels = c("DATE_MISSING", "INCONSISTENT", "CONSISTENT"))) %>%
      filter(if(plot_missing == FALSE){category != "DATE_MISSING"} else {TRUE})

    title <- "Dose sequence chronology"
    caption <- paste0(
      "Only people with at least two doses of the sequence are evaluated.\n",
      "Number of sequences with at least one date missing: ", n_missing
    )
    fill_colors <- c("CONSISTENT" = "#9cdbf4", "INCONSISTENT" = "#fabf7b", "DATE_MISSING" = "#838383")

  } else {
    # inconsistent combinations ordered by number of doses received, then by frequency.
    # CONSISTENT goes last, so it is drawn at the bottom of each bar
    sequence_order <- prepare_data %>%
      ungroup() %>%
      group_by(sequence, consistent) %>%
      summarise(n = sum(n), .groups = "drop") %>%
      mutate(n_doses = str_count(sequence, fixed(" + ")) + 1) %>%
      arrange(consistent, desc(n_doses), desc(n))

    prepare_data <- prepare_data %>%
      mutate(category = factor(sequence, levels = sequence_order$sequence))

    title <- "Dose sequence consistency"
    caption <- "Consistent: no earlier dose of the sequence is skipped."

    # CONSISTENT in blue, each inconsistent combination in a different color
    inconsistent_palette <- c(
      "#fabf7b", "#c9a3dd", "#f4a6a6", "#b5d99c", "#f7e08a", "#a0c4c7",
      "#e0b49c", "#d4a5c9", "#c2c2f0", "#f2c6de", "#d9d9a3", "#9fd8c4"
    )
    inconsistent_sequences <- sequence_order %>% filter(!consistent) %>% pull(sequence)
    fill_colors <- c(
      setNames(rep_len(inconsistent_palette, length(inconsistent_sequences)), inconsistent_sequences),
      "CONSISTENT" = "#9cdbf4"
    )
  }

  # build base plot depending on geo_level
  if(ADM_detected == 0) {
    p <- ggplot(prepare_data, aes(x = "ADM0", y = rate, fill = category))
  } else {
    p <- ggplot(
      prepare_data,
      aes(
        x = factor(
          !!sym(paste0("ADM", ADM_detected)),
          levels = sort(unique(prepare_data[[paste0("ADM", ADM_detected)]]))
        ),
        y = rate, fill = category)
    )
  }

  # do plot
  p <- p + geom_col(position = "stack") +
    labs(
      title = title,
      subtitle = sequence_name,
      x = "Geographic Area",
      y = "Rate (%)",
      caption = caption
    ) +
    scale_y_continuous(limits = c(0, 100.9), n.breaks = 5) +
    # one dose per line, since dose names can be long
    scale_fill_manual(values = fill_colors, labels = function(x) str_replace_all(x, fixed(" + "), " +\n")) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank(),
      panel.border = element_rect(fill = NA)
    )

  return(p)
}
