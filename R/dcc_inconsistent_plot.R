#' (D)ate (C)onsistency (C)omparison Inconsistent Records Plot
#'
#' Generates a histogram of absolute day differences for inconsistent records,
#' binned into customizable intervals with a final open-ended category.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param date_1 Character. The name of a DATE formatted variable present in the EIR. This variable is the date we are checking for consistency.
#' @param date_2 Character. The name of a DATE formatted variable present in the EIR. This variable is the date we are checking consistency against. Represents a date chronologically earlier than date_1.
#' @param date_1_name Character. Label for the first date variable, used in the plot subtitle. Default is \code{"date 1"}.
#' @param date_2_name Character. Label for the second date variable, used in the plot subtitle. Default is \code{"date 2"}.
#' @param day_groups List of numeric vectors of length 2. Each element is a \code{c(lower, upper)} pair defining a bin. The last bin is extended to \code{Inf} and labelled \code{"X+"}. Default is 10-day bins from 0 to 100.
#'
#' @return A ggplot object representing the histogram.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
dcc_inconsistent_plot <- function(
    data.EIR,
    date_1,
    date_2,
    date_1_name = "date 1",
    date_2_name = "date 2",
    day_groups  = list(
      c(0, 10), c(10, 20), c(20, 30), c(30, 40), c(40, 50),
      c(50, 60), c(60, 70), c(70, 80), c(80, 90), c(90, 100)
    )
) {

  .validate_data.EIR(data.EIR, required_columns = .dcc_required_cols)
  .validate_date(data.EIR[[date_1]], date_1)
  .validate_date(data.EIR[[date_2]], date_2)

  plot_data <- data.EIR %>%
    mutate(
      consistency = case_when(
        .data[[date_2]] > .data[[date_1]] ~ "INCONSISTENT",
        is.na(.data[[date_2]]) | is.na(.data[[date_1]]) ~ "DATE_MISSING",
        TRUE ~ "CONSISTENT"
      )
    )

  n_missing <- sum(plot_data$consistency == "DATE_MISSING")

  interval_labels <- sapply(day_groups, function(g) paste0(g[1], "-", g[2] - 1))
  interval_labels[length(interval_labels)] <- paste0(day_groups[[length(day_groups)]][1], "+")
  breaks <- c(sapply(day_groups, `[`, 1), Inf)
  labels <- interval_labels

  plot_data <- plot_data %>%
    filter(consistency == "INCONSISTENT") %>%
    mutate(
      delta_abs = as.numeric(abs(.data[[date_1]] - .data[[date_2]])),
      delta_cat = cut(delta_abs, breaks = breaks, labels = labels, right = FALSE, include.lowest = TRUE)
    )

  ggplot(plot_data, aes(x = delta_cat)) +
    geom_bar(fill = "#fabf7b", color = "white") +
    labs(
      title    = "Inconsistent records by day difference",
      subtitle = paste0(date_1_name, " vs ", date_2_name),
      x        = "Day difference",
      y        = "Number of records",
      caption  = paste0(
        "Absolute value of days between dates shown.\n",
        "Number of records with at least one date missing: ", n_missing
      )
    ) +
    theme_classic() +
    theme(
      axis.text.x  = element_text(angle = 45, vjust = 1, hjust = 1),
      panel.border = element_rect(fill = NA)
    )
}
