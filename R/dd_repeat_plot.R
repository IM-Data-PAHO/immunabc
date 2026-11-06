#' (D)uplicate (D)oses Repeat Plot
#'
#' Generates two histograms comparing the age of vaccination of records identified as \code{REPEATED}. Shows the age at vaccination of the \code{FIRST_ENTRY}s in one histogram, while showing the age at vaccination of the \code{REPEATED} records in the other. Comparing both helps tell apart the possible causes of repeats: for example, if the repeats of DTP1 are concentrated at the age when DTP2 is due, then the "DTP1" dose may have been registered with the wrong dose number.
#'
#' When the user provides \code{data.schedule}, a shaded area highlights the vaccination window of each dose in \code{schedule_vaccines} (using \code{age_schedule_low} and \code{age_schedule_high}). Results can also be split into columns of panels per geographic area of occurrence with \code{geo_level}.
#'
#' Records with no \code{date_birth} have no age at vaccination, and records with \code{date_vax} before \code{date_birth} have a negative one, so both are filtered out, with a message.
#'
#' @param data The output from the \code{immunabc::dd_duplicates} function.
#' @param vaccine Character. The single dose to show, e.g. "DTP1".
#' @param geo_level Character. The geographic level of occurrence to split the panels by. Must be "ADM0" (default, no split), "ADM1" or "ADM2".
#' @param within_ADM1 Character (optional). A character vector of one or several "ADM1" areas of occurrence to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param binwidth Numeric. Width of each bar of the histogram, in days. Default is 7 (one week).
#' @param max_age Numeric (optional). Maximum age at vaccination, in days, to show on the x-axis. Records after that are not shown but their number is given in the caption. Default is \code{NULL}, which shows all ages.
#' @param data.schedule Data frame (optional). A data frame defining the vaccination schedule, used to show the vaccination window of the doses in \code{schedule_vaccines}. See \code{immunABC.schedule} for expected structure. Default is \code{NULL}, which shows no schedule.
#' @param schedule_vaccines Character (optional). Up to 3 doses whose vaccination window is highlighted, e.g. \code{c("DTP1", "DTP2")}. Only used with \code{data.schedule}. If \code{NULL} (default), the vaccination window of \code{vaccine} is highlighted.
#'
#' @return A ggplot object representing the histogram.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
dd_repeat_plot <- function(data, vaccine, geo_level = "ADM0", within_ADM1 = NULL, binwidth = 7, max_age = NULL, data.schedule = NULL, schedule_vaccines = NULL) {

  # validations
  .validate_data_columns(
    data,
    c("dose", "date_birth", "date_vax", "ADM1_occurrence", "ADM2_occurrence", "group", "duplication"),
    "dd_duplicates"
  )
  .validate_character(vaccine, "vaccine", exp_len = 1)
  .validate_vaccines(vaccine, data, "data")
  .validate_character(schedule_vaccines, "schedule_vaccines", min_len = 1, max_len = 3)
  if(!is.null(data.schedule)) {
    .validate_data.schedule(data.schedule)
    if(is.null(schedule_vaccines)) {
      schedule_vaccines <- vaccine
    }
    .validate_vaccines(schedule_vaccines, data.schedule, "data.schedule")
  } else if(!is.null(schedule_vaccines)) {
    stop("Error: schedule_vaccines needs data.schedule to know their vaccination window.")
  }
  .validate_geo_level(geo_level)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_numeric(binwidth, "binwidth", exp_len = 1)
  .validate_numeric(max_age, "max_age", exp_len = 1)
  if(binwidth <= 0 || (!is.null(max_age) && max_age <= 0)) {
    stop("Error: binwidth and max_age should be greater than 0.")
  }

  # ADM1 and ADM2 refer to the place of occurrence
  geo_cols <- .geo_level_cols(geo_level)

  records <- data %>%
    ungroup() %>%  # just in case users did any grouping beforehand
    filter(dose == vaccine) %>%
    filter(if(!is.null(within_ADM1)) {ADM1_occurrence %in% within_ADM1} else {TRUE}) %>%
    mutate(ADM1 = ADM1_occurrence, ADM2 = ADM2_occurrence) %>%
    # only the groups with repeats, and only their first entry and repeats
    group_by(group) %>%
    filter(any(duplication == "REPEATED")) %>%
    ungroup() %>%
    filter(duplication %in% c("FIRST_ENTRY", "REPEATED")) %>%
    mutate(
      age = as.numeric(date_vax - date_birth),
      duplication = factor(duplication, levels = c("FIRST_ENTRY", "REPEATED"))
    )

  if(nrow(records) == 0) {
    stop("Error: There are no repeated records of ", vaccine, " in data with the specified parameters.")
  }

  # records with no date of birth have no age, and negative ages are vaccinations before birth
  n_no_age <- sum(is.na(records$age))
  n_negative <- sum(records$age < 0, na.rm = TRUE)
  if(n_no_age > 0) {
    message(paste0(n_no_age, " record(s) with no date_birth were excluded, since their age at vaccination is unknown."))
  }
  if(n_negative > 0) {
    message(paste0(n_negative, " record(s) with date_vax before date_birth were excluded."))
  }
  records <- records %>%
    filter(!is.na(age), age >= 0)

  caption <- "A repeated record refers to one with the same ID and dose but a different date or place of vaccination."

  # records after max_age are left out, so that the x-axis is not streched
  if(!is.null(max_age)) {
    n_beyond <- sum(records$age > max_age)
    records <- records %>%
      filter(age <= max_age)
    if(n_beyond > 0) {
      caption <- paste0(caption, "\n", n_beyond, " records vaccinated at more than ", max_age, " days of age are not shown.")
    }
  }

  p <- ggplot()

  # vaccination window of each dose in schedule_vaccines as a shaded area
  if(!is.null(data.schedule)) {
    window_data <- data.schedule %>%
      filter(dose %in% schedule_vaccines) %>%
      distinct(dose, .keep_all = TRUE) %>%
      mutate(window = factor(paste0(dose, " vaccination window"), levels = paste0(schedule_vaccines, " vaccination window"))) %>%
      select(window, age_schedule_low, age_schedule_high)

    p <- p +
      geom_rect(
        data = window_data,
        aes(xmin = age_schedule_low, xmax = age_schedule_high, ymin = -Inf, ymax = Inf, fill = window),
        alpha = 0.4
      ) +
      # same light colors as the vt_ module, starting with its timeliness window color
      scale_fill_manual(values = setNames(c("#9cdbf4", "#fabf7b", "#c9a3dd")[seq_along(schedule_vaccines)], levels(window_data$window)))
  }

  # do plot
  p <- p +
    geom_histogram(
      data = records,
      aes(x = age),
      binwidth = binwidth, boundary = 0, closed = "left",
      fill = "#2E9FDF", color = NA
    ) +
    # first entries and repeats share the y-axis, so their numbers can be compared
    facet_grid(
      rows = vars(duplication), cols = vars(!!!syms(geo_cols)),
      labeller = labeller(duplication = as_labeller(c(FIRST_ENTRY = "First entry", REPEATED = "Repeated")))
    ) +
    labs(
      title = paste0("Repeated doses of ", vaccine, " by age at vaccination"),
      x = "Age at vaccination (days)",
      y = "Number of records",
      caption = caption
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    theme_classic() +
    theme(
      legend.title = element_blank(),
      legend.position = "bottom",
      panel.border = element_rect(fill = NA)
    )

  if(!is.null(max_age)) {
    p <- p + coord_cartesian(xlim = c(0, max_age))
  }

  return(p)
}
