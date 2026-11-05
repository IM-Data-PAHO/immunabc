#' (D)uplicate (D)oses Rate
#'
#' This function calculates the percentage of records in the electronic immunization registry (EIR) that are duplicate doses, that is, doses entered more than once by mistake, as opposed to programmatic errors where a dose is really administered twice. Results can be disaggregated by geographic level and by one additional variable.
#'
#' Records of the same person and dose are compared in date order. The first one is not counted, since it is considered the legitimate record, and each later one is classified as either \code{DUPLICATE} or \code{REPEATED}. Only extra records are counted, so a dose registered three times counts as two. For example, the same dose registered 3 times, once on January 5, another on February 10 and once again on February 10 would count as:
#' \itemize{
#'   \item January 5: First dose, assumed to be legitimate.
#'   \item February 10: \code{REPEATED} dose, because it is the same dose on a different date.
#'   \item February 10: \code{DUPLICATE} dose, because it is registered on the same date as the previous.
#' }
#'
#' Records missing \code{ID}, \code{dose}, \code{date_vax}, \code{ADM1_occurrence} or \code{ADM2_occurrence} do not contain sufficient information to determine if they are \code{DUPLICATE} or \code{REPEATED}, so they are filtered out. \code{NA} and empty or whitespace-only text count as missing. When using \code{disaggregate_by = "birth_cohort"}, records with no \code{date_birth} are also filtered out, with a message. Finally, please note that in this analysis, geographic areas always refer to the place of occurrence of the vaccination event.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param geo_level Character. The geographic level to aggregate results by. Must be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
#' @param disaggregate_by Character (optional). One additional variable to disaggregate results by: "dose" or "birth_cohort" (year of birth). If \code{NULL} (default), there is no additional disaggregation.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. This is only a filter: use \code{disaggregate_by = "dose"} to disaggregate results by dose. If \code{NULL} (default), all doses in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which the rate should be calculated. This is only a filter: use \code{disaggregate_by = "birth_cohort"} to disaggregate results by cohort. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame with one row for each \code{duplication} category in each group, with the following columns:
#' \itemize{
#'   \item \code{ADM1}, \code{ADM2}: the geographic area of occurrence, depending on \code{geo_level}.
#'   \item \code{dose} or \code{birth_cohort}: depending on \code{disaggregate_by}.
#'   \item \code{duplication}: the category of each record, one of:
#'   \itemize{
#'     \item \code{DUPLICATE}: a duplicate record because all the columns match (ID, dose, vaccination date and place of ocurrence).
#'     \item \code{REPEATED}: a repeated dose where only the ID and dose match, but the date of vaccination or the place of ocurrence are different. May be caused by programmatic errors or by data entry errors.
#'   }
#'   \item \code{n}: number of records in that category.
#'   \item \code{total}: total number of evaluated records in the group.
#'   \item \code{rate}: percentage of records in that category (\code{n / total * 100}).
#' }
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
dd_rate <- function(data.EIR, geo_level = "ADM0", disaggregate_by = NULL, vaccines = NULL, birth_cohorts = NULL) {

  # validations
  .validate_data.EIR(data.EIR, required_columns = .dd_required_cols)
  .validate_geo_level(geo_level)
  .validate_character(disaggregate_by, "disaggregate_by", exp_len = 1)
  if(!is.null(disaggregate_by) && !(disaggregate_by %in% c("dose", "birth_cohort"))) {
    stop("Error: The disaggregate_by parameter should be one of: dose, birth_cohort (or NULL when not in use).")
  }
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  # filter and classify each record according to the duplication categories
  classified <- .dd_prepare(data.EIR, vaccines, birth_cohorts) %>%
    mutate(birth_cohort = year(date_birth))

  # When disaggregating by birth cohorts, it could be that the DoB is empty for
  # some records and so we would not be able to group them. Therefore, filter
  # these records out before grouping (and show the user a message)
  if(!is.null(disaggregate_by)) {
    n_before <- nrow(classified)
    classified <- classified %>%
      filter(!.is_missing(.data[[disaggregate_by]]))

    n_excluded <- n_before - nrow(classified)
    if(n_excluded > 0) {
      message(paste0(
        n_excluded, " record(s) (", round(n_excluded / n_before * 100, 1), "%) with no value for ",
        disaggregate_by, " were excluded."
      ))
    }
  }

  # Performs the count of duplicated and repeated records
  dd_rate <- .dd_summarise(classified, c(.geo_level_cols(geo_level), disaggregate_by))

  # Returns summary table
  return(dd_rate)
}
