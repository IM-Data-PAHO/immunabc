#' (E)ligibility (C)onsistency (C)omparison Inconsistent Records Plot
#'
#' NOTE: Not exported. The eligibility criteria are currently being redefined, so this function should not be used for the time being.
#'
#' Generates a diverging lollipop plot of ineligible records by the magnitude of days outside the scheduled age window, binned into customizable intervals with a final open-ended category. The same magnitude bins are shared by both directions on the x axis: records vaccinated too early (before \code{age_schedule_low}) are plotted below zero, and records vaccinated too late (after \code{age_schedule_high}) are plotted above zero.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param data.schedule Data frame. A data frame defining the vaccination schedule. See \code{immunABC.schedule} for expected structure.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis, faceting the plot by \code{dose} when more than one is given. If \code{NULL} (default), all doses in \code{data.schedule} are included and pooled together (no facet).
#' @param day_groups List of numeric vectors of length 2. Each element is a \code{c(lower, upper)} pair defining a magnitude bin, shared by both the "before" and "after" direction. The last bin is extended to \code{Inf}. Default is 10-day bins from 0 to 100.
#'
#' @return A ggplot object representing the diverging lollipop plot.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @keywords internal
#' @noRd
ecc_inconsistent_plot <- function(
    data.EIR,
    data.schedule,
    vaccines = NULL,
    day_groups = list(
      c(0, 10), c(10, 20), c(20, 30), c(30, 40), c(40, 50),
      c(50, 60), c(60, 70), c(70, 80), c(80, 90), c(90, 100)
    )
) {
  # NOTE: Unavailable until the eligibility criteria are redefined. The code below is kept for reference.
  message("ecc_inconsistent_plot is currently unavailable, since the eligibility criteria are being redefined.")
  return(invisible(NULL))


  # validations
  .validate_data.schedule(data.schedule)
  .validate_data.EIR(data.EIR, data.schedule)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_vaccines(vaccines, data.schedule, "data.schedule")

  # determine doses to evaluate
  doses_to_use <- data.schedule %>%
    pull(dose) %>%
    unique()
  if(!is.null(vaccines)) {
    doses_to_use <- vaccines
  }

  # prepare EIR with age at vaccination
  prepare_EIR <- data.EIR %>%
    filter(dose %in% doses_to_use) %>%
    mutate(age_at_vax = as.numeric(date_vax - date_birth))

  # Warns if any records were vaccinated before birth (points to dcc_ module)
  .validate_age_at_vax(prepare_EIR)

  plot_data <- prepare_EIR %>%
    left_join(data.schedule, by = "dose") %>%
    # Detects ineligible doses (outside the scheduled age window), also counts missing dates
    mutate(eligibility = case_when(
      is.na(date_vax) | is.na(date_birth) ~ "DATE_MISSING",
      age_at_vax < age_schedule_low | age_at_vax > age_schedule_high ~ "INELIGIBLE",
      TRUE ~ "ELIGIBLE"
    ))

  n_missing <- sum(plot_data$eligibility == "DATE_MISSING")

  # builds a magnitude label for a c(lower, upper) bin
  .label_bin <- function(g, is_last) {
    if(is_last) {
      return(paste0(g[1], "+"))
    }
    paste0(g[1], " to ", g[2] - 1)
  }

  n_groups <- length(day_groups)
  magnitude_labels <- mapply(.label_bin, day_groups, seq_len(n_groups) == n_groups)

  breaks <- c(sapply(day_groups, `[`, 1), Inf)

  # facets by dose only when vaccines is specified, matching ecc_rate/ecc_barplot behavior
  dose_group <- if(!is.null(vaccines)) "dose" else character(0)

  # Calculates day difference outside the scheduled window, bins it by magnitude, and counts records
  plot_counts <- plot_data %>%
    filter(eligibility == "INELIGIBLE") %>%
    mutate(
      days_outside_range = case_when(
        age_at_vax < age_schedule_low ~ age_at_vax - age_schedule_low,
        age_at_vax > age_schedule_high ~ age_at_vax - age_schedule_high
      ),
      direction = ifelse(days_outside_range < 0, "BEFORE", "AFTER"),
      delta_abs = abs(days_outside_range),
      bin_label = cut(delta_abs, breaks = breaks, labels = magnitude_labels, right = FALSE, include.lowest = TRUE)
    ) %>%
    count(direction, bin_label, across(all_of(dose_group))) %>%
    # Negative below zero (before schedule), positive above zero (after schedule)
    mutate(n_signed = ifelse(direction == "BEFORE", -n, n))

  plot_title <- "Ineligible records by day difference outside the scheduled window"
  if(!is.null(vaccines) && length(doses_to_use) == 1) {
    plot_title <- paste0(plot_title, " - ", doses_to_use)
  }

  # do plot
  p <- ggplot(plot_counts, aes(x = bin_label, y = n_signed, color = direction)) +
    geom_segment(aes(x = bin_label, xend = bin_label, y = 0, yend = n_signed), linewidth = 1) +
    geom_point(size = 3) +
    geom_hline(yintercept = 0, color = "black") +
    labs(
      title = plot_title,
      subtitle = "Below zero: vaccinated before age_schedule_low. Above zero: vaccinated after age_schedule_high.",
      x = "Days outside scheduled window (magnitude)",
      y = "Number of records",
      caption = paste0("Number of records with at least one date missing: ", n_missing)
    ) +
    scale_color_manual(values = c("BEFORE" = "#9cdbf4", "AFTER" = "#fabf7b")) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
      panel.border = element_rect(fill = NA),
      legend.title = element_blank()
    )

  # facets by dose when vaccines was specified with more than one dose
  if(!is.null(vaccines) && length(doses_to_use) > 1) {
    p <- p + facet_wrap(~dose)
  }

  return(p)
}
