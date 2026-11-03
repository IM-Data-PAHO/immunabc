#' Dose (S)equence (C)omparison Heatmap
#'
#' Generates a heatmap showing how people are distributed across the combinations of doses received of an ordered dose sequence (e.g. DTP1, DTP2 and DTP3), for each geographic area of residence, using data from the electronic immunization registry (EIR).
#'
#' Rows are split into consistent sequences (no dose skipped and doses in chronological order, e.g. "DTP1", "DTP1 + DTP2", "DTP1 + DTP2 + DTP3"), \code{DATE_MISSING} sequences and inconsistent sequences (e.g. "DTP1 + DTP3", or "DTP1 + DTP2 (out of order)" when the doses were not administered in chronological order). By default (\code{show_consistent = TRUE}), percentages are calculated over all people with at least one dose of the sequence in each area, so inconsistent sequences can be compared against the consistent ones. Set \code{show_consistent = FALSE} to hide consistent and \code{DATE_MISSING} sequences and deep dive into the inconsistent ones: percentages are then recalculated over the inconsistent sequences of each area only.
#'
#' Only people with at least one dose of the sequence are evaluated. Since this is a nominal indicator, each person is assigned to a single place of residence (see \code{fix_residence}).
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccines Character. A character vector of at least two doses with the ordered dose sequence to evaluate, e.g. \code{c("DTP1", "DTP2", "DTP3")}.
#' @param geo_level Character. The geographic level of residence to show as columns. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param show_consistent Logical. Whether to show consistent and \code{DATE_MISSING} sequences, with percentages over all people in each area (TRUE, default), or only inconsistent sequences, with percentages over the inconsistent sequences in each area (FALSE).
#' @param within_ADM1 Character (optional). This optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) to evaluate. If \code{NULL} (default), all available cohorts are used.
#' @param allow_same_day Logical. Whether two consecutive doses administered on the same day are considered chronologically consistent. Default is \code{FALSE}, since doses of the same vaccine series should not be administered on the same day.
#' @param fix_residence Logical. When a person's residence differs across their records, whether to correct all of that person's records to the residence of their most recent vaccination (TRUE, default) or leave the data as-is (FALSE), in which case each person is assigned the residence of their first record.
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
sc_heatmap <- function(data.EIR, vaccines, geo_level = "ADM0", show_consistent = TRUE, within_ADM1 = NULL, birth_cohorts = NULL, allow_same_day = FALSE, fix_residence = TRUE, digits = 0) {

  # validations
  .validate_data.EIR(data.EIR)
  .validate_sequence(vaccines, data.EIR)
  .validate_geo_level(geo_level)
  .validate_logical(show_consistent, "show_consistent")
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_logical(allow_same_day, "allow_same_day")
  .validate_logical(fix_residence, "fix_residence")
  .validate_numeric(digits, "digits", exp_len = 1)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  # One row per person with the combination of doses received and its classification
  sequences <- .sc_prepare(
    data.EIR,
    vaccines,
    birth_cohorts,
    fix_residence,
    check_residence = geo_level != "ADM0" || !is.null(within_ADM1)
  ) %>%
    .sc_classify_sequence(vaccines, allow_same_day) %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE}) %>%
    mutate(
      ADM0 = "ADM0",
      category = case_when(
        is.na(consistent) ~ "DATE_MISSING",
        out_of_order ~ paste0(sequence, " (out of order)"),
        TRUE ~ sequence
      ),
      group = case_when(
        is.na(consistent) ~ "Date missing",
        consistent ~ "Consistent",
        TRUE ~ "Inconsistent"
      )
    )

  # proportion of each combination of doses received in each area, over all people
  # (show_consistent = TRUE) or over people with an inconsistent sequence only (FALSE)
  plot_data <- sequences %>%
    filter(show_consistent | group == "Inconsistent") %>%
    count(area = .data[[geo_level]], group, category) %>%
    complete(area, nesting(group, category), fill = list(n = 0)) %>%
    group_by(area) %>%
    mutate(
      total = sum(n),
      proportion = round(n / total * 100, digits)
    ) %>%
    ungroup()

  # consistent sequences from fewest to most doses (the "diagonal"),
  # then inconsistent sequences from most to least frequent
  row_order <- plot_data %>%
    group_by(group, category) %>%
    summarise(n = sum(n), .groups = "drop") %>%
    mutate(n_doses = str_count(category, fixed(" + ")) + 1) %>%
    arrange(group, if_else(group == "Consistent", n_doses, -n)) %>%
    pull(category)

  plot_data <- plot_data %>%
    mutate(
      # first level is drawn at the bottom, so the order is reversed
      category = factor(category, levels = rev(row_order)),
      group = factor(group, levels = c("Consistent", "Date missing", "Inconsistent")),
      # compute text color dynamically: dark text on light background, light text on dark background
      text_color = ifelse(proportion > max(proportion) * 0.6, "white", "black"),
      label = if(geo_level == "ADM0") paste0(proportion, "%\n(n = ", n, ")") else paste0(proportion, "%")
    )

  if(show_consistent) {
    subtitle <- "Percentage of people in each area by doses received"
    caption <- paste0("Number of people with at least one dose of the sequence: ", nrow(sequences))
  } else {
    subtitle <- "Percentage of inconsistent sequences in each area by doses received"
    caption <- paste0("Number of inconsistent sequences: ", sum(sequences$group == "Inconsistent"))
  }

  # do plot
  p <- ggplot(plot_data, aes(x = area, y = category, fill = proportion)) +
    geom_tile(color = "gray") +
    geom_text(aes(label = label, colour = text_color), size = 4) +
    facet_grid(rows = vars(group), scales = "free_y", space = "free_y") +
    labs(
      title = "Dose sequences",
      subtitle = subtitle,
      x = "Residence",
      y = "Doses received",
      caption = caption
    ) +
    # gradient goes up to the highest proportion shown
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
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      strip.text.y = element_text(angle = 0)
    )

  return(p)
}
