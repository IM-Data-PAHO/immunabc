#' Validate numeric values.
#'
#' @keywords internal
#' @noRd
.validate_numeric <- function(value, value_name, min_len = NULL, exp_len = NULL, max_len = NULL) {
  if(!is.null(value) & !is.numeric(value)) {
    stop(paste0("Error: ", value_name, " should be numeric (or NULL when not in use)."))
  }

  if(!is.null(value)) {
    .validate_length(value, value_name, min_len, exp_len, max_len)
  }
}

#' Validate character values.
#'
#' @keywords internal
#' @noRd
.validate_character <- function(value, value_name, min_len = NULL, exp_len = NULL, max_len = NULL) {
  if(!is.null(value) & !is.character(value)) {
    stop(paste0("Error: ", value_name, " should be a character (or NULL when not in use)."))
  }

  if(!is.null(value)) {
    .validate_length(value, value_name, min_len, exp_len, max_len)
  }
}

#' Validate logical values.
#'
#' @keywords internal
#' @noRd
.validate_logical <- function(value, value_name) {
  if(!is.logical(value) || length(value) != 1 || is.na(value)) {
    stop(paste0("Error: ", value_name, " should be a logical value."))
  }
}

#' Validate length of vector.
#'
#' @keywords internal
#' @noRd
.validate_length <- function(value, value_name, min_len = NULL, exp_len = NULL, max_len = NULL) {
  if(!is.null(min_len)) {
    if(length(value) < min_len) {
      stop(paste0("Error: ", value_name, " should be of at least length ", min_len, "."))
    }
  }

  if(!is.null(exp_len)) {
    if(length(value) != exp_len) {
      stop(paste0("Error: ", value_name, " should be exactly of length ", exp_len, "."))
    }
  }

  if(!is.null(max_len)) {
    if(length(value) > max_len) {
      stop(paste0("Error: ", value_name, " should be of at most length ", max_len, "."))
    }
  }
}

#' Validate geo_level.
#'
#' @keywords internal
#' @noRd
.validate_geo_level <- function(geo_level, ADM_to_check = c("ADM0", "ADM1", "ADM2")) {
  .validate_character(geo_level, "geo_level", 1)

  if(!(geo_level %in% ADM_to_check)) {
    stop(
      paste0(
        "Error: The geo_level parameter should be one of: ",
        paste0(ADM_to_check, collapse = ", "),
        "."
      )
    )
  }
}

#' Validate x_axis of vt_cdf_plot and vt_pdf_plot.
#'
#' @keywords internal
#' @noRd
.validate_x_axis <- function(x_axis) {
  .validate_character(x_axis, "x_axis", exp_len = 1)

  if(is.null(x_axis) || !(x_axis %in% c("absolute", "relative"))) {
    stop("Error: The x_axis parameter should be one of: absolute, relative.")
  }
}

#' Validate data.pop according to geo_level.
#'
#' @keywords internal
#' @noRd
.validate_data.pop <- function(data.pop, geo_level) {

  if(!is.null(data.pop) & !is.data.frame(data.pop)) {
    stop("Error: data.pop should be a data frame (or NULL when not in use).")
  }

  if(!is.null(data.pop)) {
    # Check columns in data.pop based on geo_level
    has_ADM1 <- "ADM1" %in% names(data.pop)
    has_ADM2 <- "ADM2" %in% names(data.pop)

    if(geo_level == "ADM0" & (has_ADM1 | has_ADM2)) {
      stop("Error: data.pop should not contain ADM1 or ADM2.")
    } else if (geo_level == "ADM1" & (!has_ADM1 | has_ADM2)) {
      stop("Error: data.pop should only contain ADM1.")
    } else if (geo_level == "ADM2" & (!has_ADM1 | !has_ADM2)) {
      stop("Error: data.pop should contain both ADM1 and ADM2.")
    }
  }
}

#' Validate coverage_type.
#'
#' @keywords internal
#' @noRd
.validate_coverage_type <- function(coverage_type) {
  .validate_character(coverage_type, "coverage_type", 1)

  if(!(coverage_type %in% c("residence", "occurrence"))) {
    stop("Error: coverage_type should be residence or occurrence.")
  }
}

#' Validate vaccines.
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.validate_vaccines <- function(vaccines, reference_vaccines, reference_name) {
  vaccines_in_schedule <- reference_vaccines %>% pull(dose) %>% unique()

  if(!is.null(vaccines) & !all(vaccines %in% vaccines_in_schedule)) {
    stop(paste0("Error: One or more of the specified vaccines are not in ", reference_name, "."))
  }
}

#' Validate data.schedule.
#'
#' @keywords internal
#' @noRd
.validate_data.schedule <- function(data.schedule) {
  if(!is.data.frame(data.schedule)) {
    stop("Error: data.pop should be a data frame.")
  }

  if(!all(c("dose", "age_schedule", "age_schedule_low", "age_schedule_high") %in% names(data.schedule))) {
    stop("Error: data.schedule should contain the following columns: dose, age_schedule.")
  }
}


#' Validate that data is the output of a function, checking it is a data frame with the expected columns.
#'
#' @keywords internal
#' @noRd
.validate_output_data <- function(data, minimum_columns, source_function) {
  if(!is.data.frame(data)) {
    stop("Error: data should be a data frame.")
  }

  missing_columns <- setdiff(minimum_columns, names(data))

  if(length(missing_columns) > 0) {
    stop(paste0(
      "Error: data should be the output from ", source_function,
      " (missing columns: ", paste(missing_columns, collapse = ", "), ")."
    ))
  }
}

#' Validate input data to roc_barplot.
#'
#' @keywords internal
#' @noRd
.validate_roc_barplot_data <- function(data) {
  .validate_output_data(
    data,
    c("year", "dose", "doses_applied", "population", "coverage", "coverage_type"),
    "roc_coverage"
  )
}

#' Validate input data to bc_barplot.
#'
#' @keywords internal
#' @noRd
.validate_bc_barplot_data <- function(data) {
  .validate_output_data(
    data,
    c("dose", "year_cohort", "numerator", "population", "coverage"),
    "bc_coverage"
  )
}

#' Validate input data to cs_barplot.
#'
#' @keywords internal
#' @noRd
.validate_cs_barplot_data <- function(data) {
  .validate_output_data(
    data,
    c("year", "numerator", "population", "coverage"),
    "cs_coverage"
  )

  # limit number of years so palette works in plot
  number_of_years <- data %>% pull(year) %>% unique() %>% length()

  if(number_of_years > 9) {
    stop("Error: Too many years in data. Please reduce to 9 or less.")
  }
}

#' Validate input data to dcc_barplot.
#'
#' @keywords internal
#' @noRd
.validate_dcc_barplot_data <- function(data) {
  .validate_output_data(
    data,
    c("consistency", "n", "total", "rate"),
    "dcc_rate"
  )
}

#' Validate input data to ecc_barplot.
#'
#' NOTE: The eligibility criteria are currently being redefined. Review the expected columns once ecc_rate is redefined, as its output structure may change.
#'
#' @keywords internal
#' @noRd
.validate_ecc_barplot_data <- function(data) {
  .validate_output_data(
    data,
    c("eligibility", "n", "total", "rate"),
    "ecc_rate"
  )
}

#' Validate input data to vt_barplot.
#'
#' @keywords internal
#' @noRd
.validate_vt_barplot_data <- function(data) {
  .validate_output_data(
    data,
    c("timeliness", "n", "total", "rate"),
    "vt_rate"
  )
}

#' Validate input data to vt_percentile, vt_cdf_plot and vt_pdf_plot.
#'
#' @keywords internal
#' @noRd
.validate_vt_distribution_data <- function(data) {
  .validate_output_data(
    data,
    c("dose", "day", "age", "n", "pdf", "cdf", "total", "n_early", "n_missing", "window_end", "age_schedule_low"),
    "vt_distribution"
  )
}

#' Validate input data to vt_percentile_plot.
#'
#' @keywords internal
#' @noRd
.validate_vt_percentile_data <- function(data) {
  .validate_output_data(
    data,
    c("dose", "percentile", "day", "within_window", "window_end", "total"),
    "vt_percentile"
  )
}

#' Validate percentiles (numeric, between 0 and 100, 0 excluded).
#'
#' @keywords internal
#' @noRd
.validate_percentiles <- function(value, value_name, min_len = NULL, exp_len = NULL, max_len = NULL) {
  .validate_numeric(value, value_name, min_len, exp_len, max_len)

  if(!is.null(value)) {
    if(anyNA(value) || any(value <= 0 | value > 100)) {
      stop(paste0("Error: ", value_name, " should be greater than 0 and at most 100."))
    }
  }
}

#' Validate input data to roc_heatmap.
#'
#' @keywords internal
#' @noRd
.validate_roc_heatmap_data <- function(data) {
  .validate_output_data(
    data,
    c("frequency", "proportion"),
    "roc_distribution"
  )
}


#' Validate age at vaccination for negative values (vaccinated before birth).
#'
#' @keywords internal
#' @noRd
.validate_age_at_vax <- function(data) {
  n_negative <- data %>%
    filter(age_at_vax < 0) %>%
    nrow()

  if(n_negative > 0) {
    warning(
      paste0(
        "Warning: ", n_negative, " record(s) show a negative age at vaccination, meaning they were vaccinated before they were born. ",
        "This indicates date consistency errors in data.EIR. Please check the (D)ate (C)onsistency (C)omparison dcc_ module (dcc_rate, dcc_inconsistent) to identify and resolve these records."
      )
    )
  }
}

#' Validate residence consistency per ID.
#'
#' @import dplyr
#'
#' @keywords internal
#' @noRd
.validate_residence <- function(data.EIR) {
  residence_cols <- intersect(c("ADM1_residence", "ADM2_residence"), names(data.EIR))

  n_inconsistent <- data.EIR %>%
    distinct(across(all_of(c("ID", residence_cols)))) %>%
    count(ID) %>%
    filter(n > 1) %>%
    nrow()

  if(n_inconsistent > 0) {
    warning(
      paste0(
        n_inconsistent, " ID(s) have inconsistent ", paste(residence_cols, collapse = "/"),
        " across records, meaning residence is not updated to the person's most recent residence."
      )
    )
  }

  invisible(n_inconsistent)
}

#' Validate EIR duplicates.
#'
#' @keywords internal
#' @noRd
#'
.validate_duplicates <- function(data.EIR, vac_init, vac_end) {
  data.EIR <- data.EIR %>%
    filter(dose == vac_init | dose == vac_end) %>%
    mutate(dose = ifelse(dose == vac_init, "vac_init", "vac_end"))

  data_unique_rows <- data.EIR %>%
    distinct(ID, dose) %>%
    nrow()
  data_rows <- data.EIR %>%
    nrow()

  if(data_unique_rows != data_rows) {
    warning("Data contains duplicate rows where ID and dose are duplicated. We recommend you verify for duplicates before running the process to increase accuracy. ")
  }
}

#' Validate EIR duplicates for a dose sequence.
#'
#' @keywords internal
#' @noRd
.validate_duplicates_sequence <- function(data.EIR, vaccines) {
  n_duplicated <- data.EIR %>%
    filter(dose %in% vaccines) %>%
    count(ID, dose) %>%
    filter(n > 1) %>%
    nrow()

  if(n_duplicated > 0) {
    warning(
      paste0(
        "Warning: ", n_duplicated, " ID-dose combination(s) are duplicated in data.EIR. ",
        "Only the earliest date_vax of each one is kept. We recommend you verify for duplicates before running the process to increase accuracy."
      )
    )
  }
}

#' Validate a dose sequence (vaccines) for the sc_ module.
#'
#' @keywords internal
#' @noRd
.validate_sequence <- function(vaccines, data.EIR) {
  .validate_character(vaccines, "vaccines", min_len = 2)

  if(is.null(vaccines)) {
    stop("Error: vaccines should be a character vector with the ordered dose sequence, e.g. c(\"DTP1\", \"DTP2\", \"DTP3\").")
  }

  if(anyDuplicated(vaccines) > 0) {
    stop("Error: vaccines should not contain repeated doses.")
  }

  .validate_vaccines(vaccines, data.EIR, "data.EIR")
}

#' Validate input data to sc_barplot (output of sc_rate).
#'
#' @keywords internal
#' @noRd
.validate_sc_barplot_data <- function(data) {
  .validate_output_data(data, c("sequence", "consistent", "n", "total", "rate"), "sc_rate")
}

#' Validate Date object.
#'
#' @keywords internal
#' @noRd
.validate_date <- function(date_var, param_name = "date_var") {
  ## class check
  if (!inherits(date_var, "Date")) {
    stop(
      sprintf("Error: `%s` must be of class Date (got <%s>).",
              param_name, paste(class(date_var), collapse = ", ")),
      call. = FALSE
    )
  }

  invisible(TRUE)  # silent success
}

#' Validate day_groups bins.
#'
#' @keywords internal
#' @noRd
.validate_day_groups <- function(day_groups) {
  if(!is.list(day_groups) || length(day_groups) == 0 ||
     !all(sapply(day_groups, function(g) is.numeric(g) && length(g) == 2 && !anyNA(g)))) {
    stop("Error: day_groups should be a list of numeric vectors of length 2, e.g. list(c(0, 10), c(10, 20)).")
  }

  lowers <- sapply(day_groups, function(g) g[1])
  uppers <- sapply(day_groups, function(g) g[2])

  if(lowers[1] != 0) {
    stop("Error: The first bin in day_groups should start at 0.")
  }

  if(any(lowers >= uppers)) {
    stop("Error: Each bin in day_groups should have its lower value smaller than its upper value.")
  }

  # Make sure the bins are contigous (the end of one has to be the start of the next)
  # NOTES:
  #   1. uppers[-length(uppers)] keeps bins 1 to n-1
  #   2. lowers[-1] keeps bins 2 to n
  if(any(uppers[-length(uppers)] != lowers[-1])) {
    stop("Error: Bins in day_groups should be contiguous: each bin should start where the previous one ends.")
  }
}

#' Validate data.EIR structure and (optionally) schedule compatibility.
#'
#' @keywords internal
#' @noRd
.validate_data.EIR <- function(data.EIR, data.schedule = NULL, indicator = NULL) {
  if(!is.data.frame(data.EIR)) {
    stop("Error: data.EIR should be a data frame.")
  }
  if(!is.null(indicator) && indicator == "dcc"){
    required_columns <- c(
    "ID",
    "ADM1_residence",
    "ADM2_residence",
    "dose"
    )
  } else {
  required_columns <- c(
    "ID",
    "date_birth",
    "date_vax",
    "ADM1_residence",
    "ADM2_residence",
    "ADM1_occurrence",
    "ADM2_occurrence",
    "dose"
    )
  }

  if(!all(required_columns %in% names(data.EIR))) {
    stop(paste0(
      "Error: data.EIR should contain the following columns: ",
      paste(required_columns, collapse = ", "), "."
    ))
  } 

  if(!is.null(data.schedule)) {
    missing_in_schedule <- setdiff(unique(data.EIR$dose), unique(data.schedule$dose))
    if(length(missing_in_schedule) > 0) {
      warning(
        paste0(
          "Warning: The following dose(s) are present in data.EIR but missing from data.schedule: ",
          paste(missing_in_schedule, collapse = ", "),
          "."
        )
      )
    }
  }
}
