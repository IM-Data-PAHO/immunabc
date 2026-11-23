#' Construct a vector of the geographic columns used to group results:
#' empty for "ADM0", "ADM1" for "ADM1", and "ADM1" and "ADM2" for "ADM2".
#'
#' NOTE: Does not validate geo_level. Callers must validate it before calling it.
#'
#' @keywords internal
#' @noRd
.geo_level_cols <- function(geo_level) {
  switch(geo_level, ADM0 = character(0), ADM1 = "ADM1", ADM2 = c("ADM1", "ADM2"))
}

#' Compute a data frame of denominators by group from a data frame of population
#' records.
#' NOTE: Does not validate population data. Callers must validate it before
#' calling.
#'
#' @keywords internal
#' @noRd
.extract_denominators_from_population_data <- function(pop_data, groups, birth_cohorts = NULL) {
  line_list_denominator <- pop_data %>%
    select(
      ID,
      date_birth,
      ADM1 = ADM1_residence,
      ADM2 = ADM2_residence
    ) %>%
    mutate(birth_cohort = year(date_birth))

  if(!is.null(birth_cohorts)) {
    line_list_denominator <- line_list_denominator %>%
      filter(birth_cohort %in% birth_cohorts)
  }

  line_list_denominator <- line_list_denominator %>%
    distinct(ID, across(all_of(groups)))

  denominator <- line_list_denominator %>%
    group_by(across(all_of(groups))) %>%
    summarise(population = n(), .groups = "drop")

  return(denominator)
}

#' Pick the doses to analyze: the given vaccines, or every dose in data.EIR
#' when vaccines is NULL.
#' NOTE: Does not validate vaccines. Callers must validate them before calling.
#'
#' @keywords internal
#' @noRd
.doses_to_use <- function(data.EIR, vaccines = NULL) {
  if(!is.null(vaccines)) {
    return(vaccines)
  }

  data.EIR %>%
    pull(dose) %>%
    unique()
}

#' Keep the EIR records of the given doses, with residence renamed to ADM1/ADM2
#' and the birth_cohort of each person, filtered to birth_cohorts when provided.
#' NOTE: Does not validate data.EIR. Callers must validate it before calling.
#'
#' @keywords internal
#' @noRd
.prepare_EIR_doses <- function(data.EIR, doses, birth_cohorts = NULL) {
  prepare_EIR <- data.EIR %>%
    select(
      ID,
      date_birth,
      date_vax,
      ADM1 = ADM1_residence,
      ADM2 = ADM2_residence,
      dose
    ) %>%
    filter(dose %in% doses) %>%
    mutate(birth_cohort = year(date_birth))

  if(!is.null(birth_cohorts)) {
    prepare_EIR <- prepare_EIR %>% filter(birth_cohort %in% birth_cohorts)
  }

  return(prepare_EIR)
}

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

#' Enforce a single residence per ID.
#'
#' Validates that all IDs have a single residence. If there are any IDs with
#' multiple residences, then it decides what to do depending on the value
#' of fix_residence. If set to FALSE, it stops and emits a message. If set
#' to TRUE, it warns the user and then sets all records within a given ID to
#' the residence of their most recent vaccination.
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.enforce_single_residence <- function(data.EIR, fix_residence) {

  residence_cols <- intersect(c("ADM1_residence", "ADM2_residence"), names(data.EIR))

  # count how many individuals have more than one residence
  n_inconsistent <- data.EIR %>%
    distinct(across(all_of(c("ID", residence_cols)))) %>%
    count(ID) %>%
    filter(n > 1) %>%
    nrow()

  # if none, then return the data as it was given
  if(n_inconsistent == 0) {
    return(data.EIR)
  }

  # if there is at least one, tell the user
  inconsistent_msg <- paste0(
    n_inconsistent, " ID(s) have more than one place of residence across their records."
  )

  # decide what to do depending on what the user told us
  if(!fix_residence) {
    stop(
      "Error: ", inconsistent_msg, " ",
      "Correct them in data.EIR, or set fix_residence = TRUE to assign each person the residence of their most recent vaccination."
    )
  }

  # if we are fixing the residences ourselves, just emit a warning
  warning(inconsistent_msg)

  # Corrects all records of each ID to the residence of their most recent vaccination
  latest_cols <- paste0(residence_cols, "_latest")

  # obtain the residence of each individual's most recent vaccination
  latest_residence <- data.EIR %>%
    group_by(ID) %>%
    slice_max(date_vax, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(all_of(c("ID", residence_cols))) %>%
    rename_with(~ latest_cols, all_of(residence_cols))

  # add the latest residence next to each record
  data.EIR <- data.EIR %>%
    left_join(latest_residence, by = "ID")

  # overwrite each residence column with the latest one, flagging the records that change
  changed <- rep(FALSE, nrow(data.EIR))
  for(i in seq_along(residence_cols)) {
    changed <- changed | (data.EIR[[residence_cols[i]]] != data.EIR[[latest_cols[i]]])
    data.EIR[[residence_cols[i]]] <- data.EIR[[latest_cols[i]]]
  }

  # tell the user how many records were modified
  n_modified <- sum(changed)
  message(paste0(n_modified, " record(s) updated to the residence of the most recent vaccination."))

  # drop the auxiliary residence columns
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

  # Each person is assigned to a single residence
  if(check_residence) {
    # NOTE: this function will stop execution when fix_residence is FALSE and the
    #       data frame contains more than one residence per person
    data.EIR <- .enforce_single_residence(data.EIR, fix_residence)
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

#' Check which values are missing: NA, or empty or whitespace-only text in character and factor columns.
#'
#' @keywords internal
#' @noRd
.is_missing <- function(x) {
  if(is.character(x) || is.factor(x)) {
    return(is.na(x) | trimws(x) == "")
  }

  return(is.na(x))
}

#' Filter data.EIR by vaccines and birth_cohorts, then classify each record for the duplicate
#' doses (dd_) module.
#'
#' Adds three columns: \code{duplication}, \code{copy} and \code{n_copies}. Works in two steps:
#' \itemize{
#'   \item Step 1, possible repeats: records with the same ID and dose, sorted by date. The first
#'         one is FIRST_ENTRY and any later one is an extra record.
#'   \item Step 2, real duplicates: an extra record that also matches an earlier one on date_vax,
#'         ADM1_occurrence and ADM2_occurrence is a DUPLICATE. Any other extra record is REPEATED.
#' }
#' Records missing a key column do not contain sufficient information to be classified, so they are not evaluated.
#'
#' NOTE: Does not validate its inputs, and does not preserve the order of the records. Callers must
#'       validate data.EIR, vaccines and birth_cohorts before calling it.
#'
#' @import dplyr
#' @import lubridate
#'
#' @keywords internal
#' @noRd
.dd_prepare <- function(data.EIR, vaccines = NULL, birth_cohorts = NULL) {

  # Checks if the vaccines variable is used
  if(!is.null(vaccines)) {
    data.EIR <- data.EIR %>%
      filter(dose %in% vaccines)
  }

  # Checks if the birth_cohorts variable is used
  if(!is.null(birth_cohorts)) {
    data.EIR <- data.EIR %>%
      filter(year(date_birth) %in% birth_cohorts)
  }

  # Records missing a key column are not evaluated
  evaluated <- data.EIR %>%
    filter(if_all(all_of(.dd_key_cols), ~ !.is_missing(.x)))

  n_excluded <- nrow(data.EIR) - nrow(evaluated)
  if(n_excluded > 0) {
    message(paste0(
      n_excluded, " record(s) (", round(n_excluded / nrow(data.EIR) * 100, 1), "%) with missing data in ",
      paste(.dd_key_cols, collapse = ", "), " were not evaluated."
    ))
  }

  if(nrow(evaluated) == 0) {
    stop("Error: There are no records to evaluate with the specified parameters.")
  }

  # Finds the doses recorded more than once. duplicated() only flags the later copies,
  # so it runs in both directions to also flag the first one
  keys <- evaluated %>%
    select(ID, dose)
  recorded_more_than_once <- duplicated(keys) | duplicated(keys, fromLast = TRUE)

  # Doses recorded once are labelled straight away, since grouping the whole registry is slow
  recorded_once <- evaluated %>%
    filter(!recorded_more_than_once) %>%
    mutate(copy = 1L, n_copies = 1L, duplication = "FIRST_ENTRY")

  classified <- evaluated %>%
    filter(recorded_more_than_once) %>%
    arrange(ID, dose, date_vax, ADM1_occurrence, ADM2_occurrence) %>%
    # Step 1: possible repeats (same person and dose)
    group_by(ID, dose) %>%
    mutate(copy = row_number(), n_copies = n()) %>%
    # Step 2: real duplicates (also same date and place of occurrence)
    group_by(date_vax, ADM1_occurrence, ADM2_occurrence, .add = TRUE) %>%
    mutate(same_as_earlier = row_number() > 1) %>%
    ungroup() %>%
    mutate(duplication = case_when(
      copy == 1 ~ "FIRST_ENTRY",
      same_as_earlier ~ "DUPLICATE",
      TRUE ~ "REPEATED"
    )) %>%
    select(-same_as_earlier)

  return(bind_rows(recorded_once, classified))
}

#' Count the DUPLICATE and REPEATED records of each group, for dd_rate and dd_trend.
#'
#' Returns one row for each duplication category in each group of group_cols, with n, total and rate.
#' ADM1 and ADM2 refer to the place of occurrence.
#'
#' NOTE: classified must be the output of .dd_prepare, with any group column other than ADM1 and
#'       ADM2 already added.
#'
#' @import dplyr
#' @import tidyr
#'
#' @keywords internal
#' @noRd
.dd_summarise <- function(classified, group_cols) {

  classified <- classified %>%
    # rename for later usage
    mutate(ADM1 = ADM1_occurrence, ADM2 = ADM2_occurrence)

  # check we still have data after the previous steps
  if(nrow(classified) == 0) {
    stop("Error: There are no records to evaluate with the specified parameters.")
  }

  # Total records of each group, including records with no problem
  totals <- classified %>%
    count(across(all_of(group_cols)), name = "total")

  # Number of records of each category in each group
  counts <- classified %>%
    count(across(all_of(c(group_cols, "duplication"))), name = "n")

  summary <- totals %>%
    # make sure there is one row for each category in every group
    crossing(duplication = c("DUPLICATE", "REPEATED")) %>%
    left_join(counts, by = c(group_cols, "duplication")) %>%
    mutate(
      # replace the NA from empty categories for a 0
      n = replace_na(n, 0L),
      rate = n / total * 100
    ) %>%
    select(all_of(group_cols), duplication, n, total, rate)

  return(summary)
}

#' Prepare the output of dd_rate or dd_trend for the dd_ plots.
#'
#' Detects the disaggregations in data, filters by within_ADM1, keeps only the duplication category
#' to plot and builds the shared labels. geo_col, disagg_col and time_col are empty
#' character vectors when data does not have that disaggregation.
#'
#' NOTE: Does not validate its inputs. Callers must validate data, duplication, value and within_ADM1
#'       before calling it.
#'
#' @param trend Logical. Whether data should be the output of dd_trend (TRUE) or dd_rate (FALSE).
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.dd_plot_data <- function(data, duplication, value, within_ADM1 = NULL, trend = FALSE) {

  # detect the disaggregations in the data
  ADM_detected <- .detect_geo_level(data)
  geo_col <- if(ADM_detected > 0) paste0("ADM", ADM_detected) else character(0)
  disagg_col <- intersect(c("dose", "birth_cohort"), names(data))
  time_col <- intersect("month_vax", names(data))

  # trends over time come from dd_trend, and the rest of the plots from dd_rate
  if(trend && length(time_col) == 0) {
    stop("Error: data should be the output from dd_trend.")
  }
  if(!trend && length(time_col) > 0) {
    stop("Error: data should be the output from dd_rate. Use dd_trend_plot for the output of dd_trend.")
  }

  if(!is.null(within_ADM1) && !("ADM1" %in% names(data))) {
    stop("Error: within_ADM1 is only available when data is disaggregated by ADM1 or ADM2.")
  }

  # prepare data for plot
  prepare_data <- data %>%
    ungroup() %>%  # just in case users did any grouping beforehand
    filter(if(!is.null(within_ADM1)) {ADM1 %in% within_ADM1} else {TRUE})

  if(nrow(prepare_data) == 0) {
    stop("Error: There is no data to plot after filtering by within_ADM1.")
  }

  # ADM2 areas are plotted by their name alone, so names repeated across ADM1 areas would be merged
  if(ADM_detected == 2) {
    repeated_ADM2 <- prepare_data %>%
      distinct(ADM1, ADM2) %>%
      count(ADM2) %>%
      filter(n > 1) %>%
      pull(ADM2)

    if(length(repeated_ADM2) > 0) {
      stop(paste0(
        "Error: The following ADM2 names appear in more than one ADM1: ", paste(repeated_ADM2, collapse = ", "), ". ",
        "ADM2 names must be unique to be plotted, so please make them unique in data.EIR, or use within_ADM1 to plot one ADM1 at a time."
      ))
    }
  }

  # labels for the category and value shown
  is_duplicate <- duplication == "duplicate"
  axis_label <- if(value == "rate") "% of records" else "Number of records"
  subtitle <- if(value == "rate") {
      paste0("Percentage of records that are ", if(is_duplicate) "duplicates" else "repeats")
    } else {
      paste0("Number of ", if(is_duplicate) "duplicate" else "repeated", " records")
    }

  # keeps only the category to plot. Categories are in upper case in the data (e.g. "DUPLICATE")
  selected <- toupper(duplication)
  prepare_data <- prepare_data %>%
    filter(duplication == selected)

  return(list(
    data = prepare_data,
    geo_col = geo_col,
    disagg_col = disagg_col,
    time_col = time_col,
    title = if(is_duplicate) "Duplicate doses" else "Repeated doses",
    axis_label = axis_label,
    subtitle = subtitle
  ))
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
