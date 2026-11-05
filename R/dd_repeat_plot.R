#' (D)uplicate (D)oses Repeat Plot
#'
#' Generates a histogram of only repeated records as identified by \code{dd_duplicates}. Sorts them by the number of days that have passed since the vaccination date of the first entry (\code{days_since_first_entry}). This helps tell apart the possible causes of repeats: a few days apart usually points to a typo in the date, while a difference that approximately matches the interval between doses of a series may point to the next dose having been registered with the wrong dose number.
#'
#' When the user provides \code{data.schedule} and an ordered dose sequence in \code{vaccines}, each dose shows a shaded area highlighting the interval when the next dose in the series is due. This helps visually identify possible repeats that were registered with the wrong dose number. The highlighted area goes from \code{age_schedule_low} to \code{age_schedule_high} of the next dose. Since the number of repeated records is usually small, this plot is not disaggregated by geographic area.
#'
#' @param data The output from the \code{immunabc::dd_duplicates} function.
#' @param vaccines Character (optional). The doses to show, one panel per dose. When \code{data.schedule} is used, this should be an ordered dose sequence of at least two doses, as in the \code{sc_} module, e.g. \code{c("DTP1", "DTP2", "DTP3")}. If \code{NULL} (default), all doses are pooled together in a single panel.
#' @param data.schedule Data frame (optional). A data frame defining the vaccination schedule, used to show when the next dose of the sequence in \code{vaccines} is due. See \code{immunABC.schedule} for expected structure. Default is \code{NULL}, which shows no schedule.
#' @param binwidth Numeric. Width of each bar of the histogram, in days. Default is 7 (one week).
#' @param max_days Numeric. Maximum number of days since the first entry to show on the x-axis. Repeats after that are not shown but their number is given in the caption. Default is 180 days.
#'
#' @return A ggplot object representing the histogram.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
dd_repeat_plot <- function(data, vaccines = NULL, data.schedule = NULL, binwidth = 7, max_days = 180) {

  # validations
  .validate_data_columns(data, c("dose", "days_since_first_entry", "duplication"), "dd_duplicates")
  .validate_character(vaccines, "vaccines", min_len = 1)
  .validate_vaccines(vaccines, data, "data")
  if(!is.null(data.schedule)) {
    # the next dose is only defined within an ordered sequence of doses
    if(is.null(vaccines)) {
      stop("Error: data.schedule needs an ordered dose sequence in vaccines, e.g. c(\"DTP1\", \"DTP2\", \"DTP3\").")
    }
    .validate_sequence(vaccines, data)
    .validate_data.schedule(data.schedule)
    .validate_vaccines(vaccines, data.schedule, "data.schedule")
  }
  .validate_numeric(binwidth, "binwidth", exp_len = 1)
  .validate_numeric(max_days, "max_days", exp_len = 1)
  if(binwidth <= 0 || max_days <= 0) {
    stop("Error: binwidth and max_days should be greater than 0.")
  }

  # get only the repeated records
  repeats <- data %>%
    filter(duplication == "REPEATED") %>%
    mutate(days = days_since_first_entry)

  # keeps only the doses in vaccines, in their order, one panel each
  if(!is.null(vaccines)) {
    repeats <- repeats %>%
      filter(dose %in% vaccines) %>%
      mutate(dose = factor(dose, levels = vaccines))
  }

  if(nrow(repeats) == 0) {
    stop("Error: There are no repeated records in data.")
  }

  # repeats after max_days are left out, so a few very late ones do not stretch the x-axis
  n_beyond <- sum(repeats$days > max_days)
  repeats <- repeats %>%
    filter(days <= max_days)

  caption <- "Repeated means an extra record with the same ID and dose but a different date or place of vaccination."
  if(n_beyond > 0) {
    caption <- paste0(caption, "\n", n_beyond, " repeated records occur more than ", max_days, " days after the first entry.")
  }

  p <- ggplot()

  # calculations to show the schedule as a highlighted area
  if(!is.null(data.schedule)) {
    # calculate when the next dose of the sequence is due
    due_data <- data.schedule %>%
      filter(dose %in% vaccines) %>%
      distinct(dose, .keep_all = TRUE) %>%
      # order according to the sequence provided in vaccines
      arrange(match(dose, vaccines)) %>%
      mutate(
        due_low = lead(age_schedule_low) - age_schedule,
        due_high = lead(age_schedule_high) - age_schedule,
        dose = factor(dose, levels = vaccines)
      ) %>%
      # the last dose in the sequence has no next dose
      filter(!is.na(due_low)) %>%
      select(dose, due_low, due_high) %>%
      # cut to the days shown
      mutate(due_low = pmax(due_low, 0), due_high = pmin(due_high, max_days)) %>%
      filter(due_low < max_days)

    # shaded area represents the time during which a repeated dose may
    # simply be a future dose that was mislabelled
    p <- p +
      geom_rect(
        data = due_data,
        aes(xmin = due_low, xmax = due_high, ymin = -Inf, ymax = Inf, fill = "Timeliness window"),
        alpha = 0.4
      ) +
      scale_fill_manual(values = c("Timeliness window" = "#9cdbf4"))
  }

  # do plot
  p <- p +
    geom_histogram(
      data = repeats,
      aes(x = days),
      binwidth = binwidth, boundary = 0, closed = "left",
      fill = "#c9a3dd", color = "white"
    ) +
    labs(
      title = "Repeated doses by days since the first entry",
      x = "Days since the first entry of the same person and dose",
      y = "Number of records",
      caption = caption
    ) +
    coord_cartesian(xlim = c(0, max_days)) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    theme_classic() +
    theme(
      legend.title = element_blank(),
      legend.position = "bottom",
      panel.border = element_rect(fill = NA)
    )

  if(!is.null(vaccines)) {
    # each dose has its own y-axis, so the shape of its distribution can be compared
    p <- p + facet_wrap(vars(dose), scales = "free_y")
  }

  return(p)
}
