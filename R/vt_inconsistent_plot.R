#' (V)accination (T)imeliness Inconsistent Records Plot
#'
#' Generates a lollipop plot showing the distribution of untimely records, grouping them in bins of days outside of the timeliness window. The \code{UNTIMELY_LATE} records and the \code{UNTIMELY_EARLY} records are shown in separate rows.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param data.schedule Data frame. A data frame defining the vaccination schedule. See \code{immunABC.schedule} for expected structure.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all doses in \code{data.schedule} are included and pooled together.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) to include in the plot. If \code{NULL} (default), all available cohorts are used. Note that specifying cohorts excludes records with no \code{date_birth}, so the \code{DATE_MISSING} category may be undercounted.
#' @param day_groups List of numeric vectors of length 2. Each element is a \code{c(lower, upper)} pair defining each bin's lower and upper limit in days. Bins must start at 0 and be contiguous (each bin starts where the previous one ends). The last bin is extended to \code{Inf}, so its upper value is ignored (e.g. \code{c(90, 120)} and \code{c(90, 100)} both produce a "90+" bin). Default is 10-day bins from 0 to 100.
#'
#' @return A ggplot object representing the lollipop plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
vt_inconsistent_plot <- function(
    data.EIR,
    data.schedule,
    vaccines = NULL,
    birth_cohorts = NULL,
    day_groups = list(
      c(0, 10), c(10, 20), c(20, 30), c(30, 40), c(40, 50),
      c(50, 60), c(60, 70), c(70, 80), c(80, 90), c(90, 100)
    )
) {

  # validations
  .validate_data.schedule(data.schedule)
  .validate_data.EIR(data.EIR)
  .validate_schedule_doses(data.EIR, data.schedule)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_vaccines(vaccines, data.schedule, "data.schedule")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_day_groups(day_groups)

  plot_data <- .vt_classify(data.EIR, data.schedule, vaccines, birth_cohorts)

  n_missing <- sum(plot_data$timeliness == "DATE_MISSING")

  # builds a magnitude label for a c(lower, upper) bin
  .label_bin <- function(g, is_last) {
    if(is_last) {
      return(paste0(g[1], "+"))
    }
    paste0(g[1], " to ", g[2] - 1)
  }

  # number of bins
  n_groups <- length(day_groups)
  # one label per bin, e.g. "0 to 9"; the last bin gets an open-ended label, e.g. "90+"
  magnitude_labels <- mapply(.label_bin, day_groups, seq_len(n_groups) == n_groups)

  # cut points: the lower value of each bin, plus Inf so the last bin has no upper limit
  breaks <- c(sapply(day_groups, function(g) g[1]), Inf)

  # facet by dose only when vaccines is specified
  dose_group <- if(!is.null(vaccines)) "dose" else character(0)

  # Calculates day difference outside the timeliness window, bins it by magnitude, and counts records
  plot_counts <- plot_data %>%
    # keeps only untimely (early or late) records
    filter(timeliness %in% c("UNTIMELY_EARLY", "UNTIMELY_LATE")) %>%
    # adds bin labelling
    mutate(
      delta_abs = abs(days_outside_range),
      bin_label = cut(delta_abs, breaks = breaks, labels = magnitude_labels, right = FALSE, include.lowest = TRUE)
    ) %>%
    # counts records per timeliness type and bin (and dose, if vaccines is specified)
    count(timeliness, bin_label, across(all_of(dose_group))) %>%
    # shows late above early in the facet rows
    mutate(timeliness = factor(timeliness, levels = c("UNTIMELY_LATE", "UNTIMELY_EARLY")))

  # total untimely records per timeliness type, for the caption
  n_early <- sum(plot_counts$n[plot_counts$timeliness == "UNTIMELY_EARLY"])
  n_late <- sum(plot_counts$n[plot_counts$timeliness == "UNTIMELY_LATE"])

  # do plot
  p <- ggplot(plot_counts, aes(x = bin_label, y = n, color = timeliness)) +
    geom_segment(aes(x = bin_label, xend = bin_label, y = 0, yend = n), linewidth = 1) +
    geom_point(size = 3) +
    labs(
      title = "Untimely records by day difference outside the timeliness window",
      x = "Days outside timeliness window (absolute value)",
      y = "Number of records",
      caption = paste0(
        "Vaccinated before the timeliness window: ", n_early,
        ". Vaccinated after the timeliness window: ", n_late, ".\n",
        "Number of records with at least one date missing: ", n_missing
      )
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05)), limits = c(0, NA)) +
    scale_color_manual(values = c("UNTIMELY_EARLY" = "#c9a3dd", "UNTIMELY_LATE" = "#fabf7b")) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
      panel.border = element_rect(fill = NA),
      # facet is already specifying the same thing the legend would
      legend.position = "none"
    )

  timeliness_labels <- labeller(timeliness = c(
    "UNTIMELY_LATE" = "Late (after age_schedule_high)",
    "UNTIMELY_EARLY" = "Early (before age_schedule_low)"
  ))
  if(!is.null(vaccines)) {
    # facet both by timeliness and dose
    p <- p + facet_grid(rows = vars(timeliness), cols = vars(dose), scales = "free_y", labeller = timeliness_labels)
  } else {
    # since all doses are pooled together, facet only by timeliness
    p <- p + facet_grid(rows = vars(timeliness), scales = "free_y", labeller = timeliness_labels)
  }

  return(p)
}
