#' Detect the smallest admin level in a data frame.
#'
#' @keywords internal
#' @noRd
.detect_geo_level <- function(data) {

  columns_in_data <- names(data)
  ADM_detected <- 0

  # remove _residence or _ocurrence suffixes
  columns_in_data <- str_remove(columns_in_data, "_residence")
  columns_in_data <- str_remove(columns_in_data, "_ocurrence")

  if(any(c("ADM1", "ADM2") %in% columns_in_data)) {
    if("ADM2" %in% columns_in_data) {
      ADM_detected <- 2
      message("ADM2 detected.")
    } else {
      ADM_detected <- 1
      message("ADM1 detected.")
    }
  } else{
    ADM_detected <- 0
    message("ADM0 detected.")
  }

  return(ADM_detected)

}

#' Correct residence per ID to the residence of the most recent vaccination record.
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.fix_residence <- function(data.EIR) {

  residence_cols <- intersect(c("ADM1_residence", "ADM2_residence"), names(data.EIR))
  latest_cols <- paste0(residence_cols, "_latest")

  latest_residence <- data.EIR %>%
    group_by(ID) %>%
    slice_max(date_vax, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(all_of(c("ID", residence_cols))) %>%
    rename_with(~ latest_cols, all_of(residence_cols))

  data.EIR <- data.EIR %>%
    left_join(latest_residence, by = "ID")

  changed <- rep(FALSE, nrow(data.EIR))
  for(i in seq_along(residence_cols)) {
    changed <- changed | (data.EIR[[residence_cols[i]]] != data.EIR[[latest_cols[i]]])
    data.EIR[[residence_cols[i]]] <- data.EIR[[latest_cols[i]]]
  }

  n_modified <- sum(changed)
  message(paste0(n_modified, " record(s) had residence updated to the most recent vaccination residence."))

  data.EIR <- data.EIR %>%
    select(-all_of(latest_cols))

  return(data.EIR)
}

#' Convert the vaccination schedule from days to years. Automatically rounds down to lowest whole year.
#'
#' @keywords internal
#' @noRd
.schedule_to_years <- function(data.schedule) {

  # convert age column from days to years
  converted <- data.schedule %>% mutate(age_schedule = floor(age_schedule / 365))

  return(converted)
}

#' Classify each EIR record as TIMELY, UNTIMELY_EARLY, UNTIMELY_LATE or DATE_MISSING according to the timeliness window in data.schedule, and compute its days_outside_range.
#'
#' NOTE: Does not validate its inputs (it only warns about negative ages at vaccination). Callers must validate data.EIR, data.schedule, vaccines and birth_cohorts before calling it.
#'
#' @import dplyr
#' @import lubridate
#'
#' @keywords internal
#' @noRd
.vt_classify <- function(data.EIR, data.schedule, vaccines = NULL, birth_cohorts = NULL) {

  # Checks if the birth_cohorts variable is used
  if(!is.null(birth_cohorts)) {
    data.EIR <- data.EIR %>%
      filter(year(date_birth) %in% birth_cohorts)
  }

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

  classified <- prepare_EIR %>%
    left_join(data.schedule, by = "dose") %>%
    # Clasify timely, early (before the timeliness window), late (after it) and date missing
    mutate(timeliness = case_when(
      is.na(date_vax) | is.na(date_birth) ~ "DATE_MISSING",
      age_at_vax < age_schedule_low ~ "UNTIMELY_EARLY",
      age_at_vax > age_schedule_high ~ "UNTIMELY_LATE",
      TRUE ~ "TIMELY"
    )) %>%
    # Days outside the timeliness window: negative if before age_schedule_low,
    # positive if after age_schedule_high, NA for TIMELY and DATE_MISSING records
    mutate(days_outside_range = case_when(
      age_at_vax < age_schedule_low ~ age_at_vax - age_schedule_low,
      age_at_vax > age_schedule_high ~ age_at_vax - age_schedule_high
    ))

  return(classified)
}

#' Prepare the EIR for the dose sequence comparison (sc_) module.
#'
#' Filters by birth_cohorts, checks (and optionally fixes) residence consistency per ID,
#' keeps only the doses in vaccines and removes duplicated ID-dose records, keeping the earliest date_vax.
#' Returns one row per ID and dose received, with residence renamed to ADM1 and ADM2.
#'
#' NOTE: Does not validate its inputs. Callers must validate data.EIR, vaccines, birth_cohorts
#'       and fix_residence before calling it.
#'
#' @import dplyr
#' @import lubridate
#'
#' @keywords internal
#' @noRd
.sc_prepare <- function(data.EIR, vaccines, birth_cohorts = NULL, fix_residence = TRUE, check_residence = TRUE) {

  # Checks if the birth_cohorts variable is used
  if(!is.null(birth_cohorts)) {
    data.EIR <- data.EIR %>%
      filter(year(date_birth) %in% birth_cohorts)
  }

  # Checks residence consistency per ID, since each person is assigned to a single residence
  if(check_residence) {
    n_inconsistent <- .validate_residence(data.EIR)

    if(fix_residence) {
      data.EIR <- .fix_residence(data.EIR)
    } else if(n_inconsistent > 0) {
      warning(
        "Residence inconsistencies were not corrected (fix_residence = FALSE). ",
        "Each person will be assigned the residence of their first record in data.EIR, or set fix_residence = TRUE."
      )
    }
  }

  prepare_EIR <- data.EIR %>%
    filter(dose %in% vaccines) %>%
    select(ID, date_birth, date_vax, ADM1 = ADM1_residence, ADM2 = ADM2_residence, dose)

  # Warns about duplicated ID-dose records, then keeps the earliest date_vax of each one
  .validate_duplicates_sequence(prepare_EIR, vaccines)

  prepare_EIR <- prepare_EIR %>%
    # NA dates are sorted last, so they are only kept when there is no other date for that dose
    arrange(ID, dose, date_vax) %>%
    distinct(ID, dose, .keep_all = TRUE) %>%
    # each person keeps a single residence and date of birth
    group_by(ID) %>%
    mutate(
      ADM1 = first(ADM1),
      ADM2 = first(ADM2),
      date_birth = first(date_birth)
    ) %>%
    ungroup()

  return(prepare_EIR)
}

#' Summarise the doses received per person for the dose sequence comparison (sc_) module.
#'
#' Returns one row per ID with its residence, date of birth, the combination of doses received
#' (\code{sequence}, e.g. "DTP1 + DTP3", following the order in vaccines) and the checks behind
#' its classification:
#' \itemize{
#'   \item \code{skipped}: an earlier dose of the sequence is missing (e.g. "DTP1 + DTP3").
#'   \item \code{out_of_order}: a dose was administered before (or, unless allow_same_day, on the
#'         same day as) the previous dose received in the sequence.
#'   \item \code{date_missing}: at least two doses received and at least one with no date_vax, so
#'         the chronological order cannot be fully evaluated.
#'   \item \code{consistent}: FALSE if skipped or out_of_order, NA if not but date_missing,
#'         TRUE otherwise. Unfinished sequences (e.g. "DTP1 + DTP2") can be consistent.
#' }
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.sc_classify_sequence <- function(prepare_EIR, vaccines, allow_same_day = FALSE) {

  classified <- prepare_EIR %>%
    # sort each person's doses following the order of the sequence
    mutate(dose_order = match(dose, vaccines)) %>%
    arrange(ID, dose_order) %>%
    group_by(ID, date_birth, ADM1, ADM2) %>%
    # days since the previous dose received in the sequence
    mutate(days_since_previous = as.numeric(date_vax - lag(date_vax))) %>%
    summarise(
      sequence = paste(dose, collapse = " + "),
      # positions of the doses received must be 1, 2, ..., k with no gaps
      skipped = !identical(dose_order, seq_len(n())),
      out_of_order = if(allow_same_day) {
        any(days_since_previous < 0, na.rm = TRUE)
      } else {
        any(days_since_previous <= 0, na.rm = TRUE)
      },
      date_missing = n() >= 2 & anyNA(date_vax),
      .groups = "drop"
    ) %>%
    mutate(consistent = case_when(
      skipped | out_of_order ~ FALSE,
      date_missing ~ NA,
      TRUE ~ TRUE
    ))

  return(classified)
}

#' Compute the daily (pdf) and cumulative (cdf) distribution of vaccinations from daily counts.
#'
#' NOTE: data must already be grouped according to the disaggregation levels required,
#'       it must also contain the number of records vaccinated on each day (n) and it should
#'       be sorted by day within each group (for cumulative sum to work)
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.vt_compute_distribution <- function(data) {

  distributions <- data %>%
    mutate(
      total = sum(n),
      pdf = n / total * 100,
      cum_n = cumsum(n),
      cdf = cum_n / total * 100,
      # records not yet vaccinated at the start of each day
      n_at_risk = total - lag(cum_n, default = 0)
    )

  return(distributions)
}

#' Prepare the data shared by vt_cdf_plot and vt_pdf_plot.
#'
#' Filters by within_ADM1, checks the areas in highlight, combines all areas into a single
#' distribution per dose, and computes the percentile labels, default max_days, subtitle and caption.
#'
#' NOTE: Does not validate its inputs. Callers must validate data, percentile, highlight,
#'       within_ADM1 and max_days before calling it.
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.vt_distribution_plot_data <- function(data, percentile, highlight, within_ADM1, max_days) {

  # detect geo level
  ADM_detected <- .detect_geo_level(data)
  subnational_detected <- ADM_detected > 0
  geo_col <- if(subnational_detected) paste0("ADM", ADM_detected) else NULL

  group_cols <- intersect(c("dose", "ADM1", "ADM2"), names(data))

  # prepare data for plot
  prepare_data <- data %>%
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  # check that the areas to highlight exist
  if(!is.null(highlight)) {
    if(!subnational_detected) {
      stop("Error: highlight is only available when data is disaggregated by ADM1 or ADM2.")
    }
    missing_areas <- setdiff(highlight, prepare_data[[geo_col]])
    if(length(missing_areas) > 0) {
      stop(paste0("Error: The following areas in highlight are not in data: ", paste(missing_areas, collapse = ", "), "."))
    }
  }

  # Combine all areas in the data and calculate some summary numbers
  combined_totals <- prepare_data %>%
    distinct(across(all_of(group_cols)), total, n_early, n_missing) %>%
    group_by(dose) %>%
    summarise(total = sum(total), n_early = sum(n_early), n_missing = sum(n_missing), .groups = "drop")

  # Sum together all areas in the data and get the combined distribution of each dose
  combined_data <- prepare_data %>%
    group_by(dose, day, age) %>%
    summarise(
      n = sum(n), window_end = first(window_end), age_schedule_low = first(age_schedule_low),
      .groups = "drop"
    ) %>%
    group_by(dose) %>%
    .vt_compute_distribution() %>%
    ungroup() %>%
    # adds the excluded records, so combined_data has the same structure as the output of vt_distribution
    left_join(combined_totals %>% select(dose, n_early, n_missing), by = "dose")

  # Series drawn in color: all areas combined + the highlighted areas
  combined_label <- if(subnational_detected) "All areas combined" else "ADM0"
  series_levels <- c(combined_label, highlight)
  series_colors <- setNames(
    c("#2E9FDF", "#E66100", "#5D3A9B", "#1B9E77", "#D41159", "#8C510A")[seq_along(series_levels)],
    series_levels
  )

  highlight_data <- NULL
  if(!is.null(highlight)) {
    highlight_data <- prepare_data %>%
      filter(!!sym(geo_col) %in% highlight)
  }

  # a function that returns the number of days needed for each colored series to reach a percentile
  series_percentile <- function(p) {
    bind_rows(
      vt_percentile(combined_data, p) %>% mutate(series = combined_label),
      if(!is.null(highlight_data)) vt_percentile(highlight_data, p) %>% mutate(series = !!sym(geo_col))
    ) %>%
      mutate(series = factor(series, levels = series_levels))
  }

  # By default, shows up to the day where 95% is vaccinated in every colored series,
  # so a few very late (or wrongly dated) records do not stretch the x-axis
  if(is.null(max_days)) {
    max_days <- max(series_percentile(95)$day)
    message(paste0("Showing up to day ", max_days, " (95th percentile). Use max_days to change it."))
  }

  # distribution of each colored series
  series_data <- bind_rows(
    combined_data %>% mutate(series = combined_label),
    if(!is.null(highlight_data)) highlight_data %>% mutate(series = !!sym(geo_col))
  ) %>%
    mutate(series = factor(series, levels = series_levels))

  # distribution of each geographic area, drawn as grey lines for context
  area_data <- NULL
  if(subnational_detected) {
    area_data <- prepare_data %>%
      mutate(series = !!sym(geo_col))
  }

  # start and last timely day of each dose, for the shaded area
  window_data <- combined_data %>%
    distinct(dose, window_end, age_schedule_low)

  # number of excluded records for the plot's caption
  excluded <- combined_totals %>%
    summarise(total = sum(total), n_early = sum(n_early), n_missing = sum(n_missing))
  pct_early <- excluded$n_early / (excluded$total + excluded$n_early) * 100
  caption <- paste0(
    "Vaccinated before the timeliness window (excluded): ", excluded$n_early,
    " (", round(pct_early, 1), "%).\n",
    "Number of records with at least one date missing (excluded): ", excluded$n_missing
  )

  # subtitle explaining the grey lines (the shaded area is explained in the legend)
  subtitle <- if(subnational_detected) paste0("Grey lines: each ", geo_col, " area") else NULL

  # return a list of several objects used by the vt_pdf_plot and vt_cdf_plot functions
  return(list(
    subnational_detected = subnational_detected,
    series_data = series_data,
    combined_label = combined_label,
    series_colors = series_colors,
    area_data = area_data,
    window_data = window_data,
    percentile_data = if(!is.null(percentile)) series_percentile(percentile) else NULL,
    max_days = max_days,
    subtitle = subtitle,
    caption = caption
  ))
}
