#' (Z)ero (D)ose Rate Bar Plot
#'
#' Generates a bar plot of the zero-dose rate, grouped by geographic area and colored by birth cohort year. When several vaccines are plotted, each one is shown in its own panel.
#'
#' @param data Data frame. The output from the \code{immunabc::zd_rate} function.
#' @param vaccine Character (optional). A vector specifying the vaccine(s) to plot, one panel per vaccine. If \code{NULL} (default), the combined "All" rate is plotted when present in \code{data} (that is, when \code{zd_rate} was run without \code{vaccines}); otherwise every vaccine in \code{data} is plotted.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) to plot. If \code{NULL} (default), all years are plotted.
#' @param within_ADM1 Character (optional). When analyzing data at the "ADM2" level, this optional character vector lets you specify one or several "ADM1" to filter. Default is \code{NULL}, which means no filtering by "ADM1".
#' @param palette Character (optional). A RColorBrewer palette name for the cohort colors. Default is \code{"YlOrBr"}.
#'
#' @return A ggplot object representing the bar plot. Negative zero-dose rates (more vaccinated people than population) are drawn as their absolute value with a red outline.
#'
#' @import dplyr
#' @import ggplot2
#'
#' @export
zd_barplot <- function(data, vaccine = NULL, birth_cohorts = NULL, within_ADM1 = NULL, palette = "YlOrBr") {

  .validate_zd_barplot_data(data)
  .validate_character(vaccine, "vaccine", min_len = 1)
  .validate_vaccines(vaccine, data, "data")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_character(within_ADM1, "within_ADM1", min_len = 1)
  .validate_character(palette, "palette", exp_len = 1)

  # detect geo level
  ADM_detected <- .detect_geo_level(data)
  geo_column <- paste0("ADM", ADM_detected)

  # pick vaccines to plot
  single_doses <- setdiff(unique(data$dose), "All")
  if(is.null(vaccine)) {
    doses_to_plot <- if("All" %in% data$dose) "All" else single_doses
  } else {
    doses_to_plot <- unique(vaccine)
  }

  plots_all <- identical(doses_to_plot, "All") ||
    (length(doses_to_plot) > 1 && all(single_doses %in% doses_to_plot))
  title_vaccines <- if(plots_all) "All" else paste(doses_to_plot, collapse = ", ")

  # prepare data for plot
  prepare_data <- data %>%
    filter(dose %in% doses_to_plot) %>%
    filter(!is.na(zd_rate)) %>%
    filter(if(!is.null(birth_cohorts)) {birth_cohort %in% birth_cohorts} else {TRUE}) %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  cohort_levels <- prepare_data %>%
    pull(birth_cohort) %>%
    unique() %>%
    sort()

  if(length(cohort_levels) > 9) {
    cohort_levels <- tail(cohort_levels, 9)
    prepare_data <- prepare_data %>%
      filter(birth_cohort %in% cohort_levels)
    warning("Data has more than 9 birth cohorts; keeping only the 9 latest cohorts for plotting.")
  }

  prepare_data <- prepare_data %>%
    mutate(
      birth_cohort = factor(birth_cohort, levels = cohort_levels),
      dose = factor(dose, levels = doses_to_plot),
      negative = !is.na(zd_rate) & zd_rate < 0,
      zd_plot = abs(zd_rate)
    )

  # get max zero-dose rate in data
  zd_max <- max(prepare_data$zd_plot, na.rm = TRUE)
  zd_max <- ceiling(zd_max * 10) / 10 # round to tenth above
  zd_max <- max(100, zd_max) # make sure its always at least 100

  # do plot
  if(ADM_detected == 0) {
    p <- ggplot(prepare_data, aes(x = "ADM0", y = zd_plot, fill = birth_cohort))
  } else {
    p <- ggplot(
      prepare_data,
      aes(x = reorder(!!sym(geo_column), -zd_plot), y = zd_plot, fill = birth_cohort)
    )
  }

  p <- p +
    geom_col(aes(colour = negative), position = "dodge", linewidth = 0.8) +
    scale_colour_manual(values = c(`FALSE` = NA, `TRUE` = "red"), guide = "none") +
    labs(
      title = paste0("Zero-Dose Rate, ", title_vaccines),
      x = "Geographic Area",
      y = "Zero-dose rate (%)",
      caption = if(any(prepare_data$negative)) {
        "Red outline: negative rate (more vaccinated people than population), shown as its absolute value."
      } else {
        NULL
      }
    ) +
    scale_y_continuous(breaks = seq(0, zd_max, 25), limits = c(0, zd_max)) +
    scale_fill_brewer(palette = palette) +
    theme_classic() +
    theme(
      axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.title = element_blank()
    )

  if(length(doses_to_plot) > 1) {
    p <- p + facet_wrap(~ dose, scales = "free_x")
  }

  return(p)
}
