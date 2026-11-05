#' (D)uplicate (D)oses Records
#'
#' This function returns a record-level table of the doses recorded more than once for the same person, so they can be reviewed and corrected in the electronic immunization registry (EIR). Each of these doses shows all of its records, including the first one, so the later records can be compared against it.
#'
#' Records missing \code{ID}, \code{dose}, \code{date_vax}, \code{ADM1_occurrence} or \code{ADM2_occurrence} cannot be shown to match another record, so they are filtered out. Please note that \code{NA} and empty text count as missing.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccines Character (optional). A character vector specifying the doses to include. If \code{NULL} (default), all doses in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) for which records should be returned. If \code{NULL} (default), all available cohorts are used.
#'
#' @return A data frame with one row per record, with the following columns:
#' \itemize{
#'   \item \code{ID}, \code{date_birth}, \code{dose}, \code{date_vax}, \code{ADM1_occurrence}, \code{ADM2_occurrence}.
#'   \item \code{group}: a unique number that identifies all records of the same person and dose.
#'   \item \code{copy}: position of the record within its group, in date order.
#'   \item \code{n_copies}: total number of records for that person and dose.
#'   \item \code{days_since_first_entry}: number of days between the record and the \code{FIRST_ENTRY} of its group (\code{NA} for the \code{FIRST_ENTRY} itself).
#'   \item \code{duplication}: the category of the record, one of:
#'   \itemize{
#'     \item \code{FIRST_ENTRY}: the first record of that person and dose, shown for comparison.
#'     \item \code{REPEATED}: extra record with the same ID and dose as an earlier record, but a different date or place of occurrence. It may be a dose really administered twice.
#'     \item \code{DUPLICATE}: extra record with the same ID, dose, vaccination date and place of occurrence as an earlier record.
#'   }
#' }
#'
#' @import dplyr
#' @import lubridate
#'
#' @export
dd_duplicates <- function(data.EIR, vaccines = NULL, birth_cohorts = NULL) {

  # validations
  .validate_data.EIR(data.EIR, required_columns = .dd_required_cols)
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_date(data.EIR$date_birth, "date_birth")
  .validate_date(data.EIR$date_vax, "date_vax")

  # filter and classify each record according to the duplication categories
  duplicates <- .dd_prepare(data.EIR, vaccines, birth_cohorts) %>%
    # keep only records with duplicates/repeats
    filter(n_copies > 1) %>%
    arrange(desc(n_copies), ID, dose, copy) %>%
    # each group starts at its first record because of the sorting
    mutate(group = cumsum(copy == 1)) %>%
    # days between each record and the first entry of its group
    group_by(group) %>%
    mutate(days_since_first_entry = if_else(copy == 1, NA_real_, as.numeric(date_vax - date_vax[copy == 1]))) %>%
    ungroup()

  # Prepares the table of records
  dd_duplicates <- duplicates %>%
    select(
      ID, date_birth, dose, date_vax,
      ADM1_occurrence, ADM2_occurrence,
      group, copy, n_copies, days_since_first_entry, duplication
    )

  # Returns the record-level table
  return(dd_duplicates)
}
