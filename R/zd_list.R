#' (Z)ero (D)ose List
#'
#' This function lists each person with the date of each of a given set of vaccines, using data from the electronic immunization registry (EIR), and classifies them by how many of those vaccines they have received.
#'
#' @param data.EIR Data frame. A data frame containing individual vaccination records. See \code{immunABC.EIR} for expected structure.
#' @param vaccines Character (optional). A character vector specifying the doses to include in the analysis. If \code{NULL} (default), all vaccines in \code{data.EIR} are included.
#' @param birth_cohorts Numeric (optional). A vector specifying the birth cohort(s) of the people to list. If \code{NULL} (default), every person is listed regardless of birth year.
#' @param data.pop_ids Data frame (optional). A data frame with individual population records (such as a civil registry) that can be cross-referenced with the EIR. See \code{immunABC.pop_ids} for expected structure. If provided, the people listed are taken from it instead of \code{data.EIR}.
#' @return A data frame with one row per person, the earliest date of each of the \code{vaccines} and a \code{Category} column: "COMPLETE" if the person has all of them, "PARTIAL" if they have some, and "ZERO_DOSE" if they have none. It includes \code{name} when \code{data.pop_ids} is provided.
#'
#' @import dplyr
#' @import lubridate
#' @import tidyr
#'
#' @export
zd_list <- function(data.EIR, vaccines = NULL, birth_cohorts = NULL, data.pop_ids = NULL) {

  # validations
  .validate_data.EIR(data.EIR)
  .validate_vaccines(vaccines, data.EIR, "data.EIR")
  .validate_numeric(birth_cohorts, "birth_cohorts", min_len = 1)
  .validate_data.pop_ids(data.pop_ids)

  # determine vaccines to evaluate
  doses_to_use <- .doses_to_use(data.EIR, vaccines)

  # one row per person to list
  if(!is.null(data.pop_ids)) {
    pop_table <- data.pop_ids %>%
      select(
        ID,
        name,
        date_birth,
        ADM1_residence,
        ADM2_residence
      )
  } else {
    pop_table <- data.EIR %>%
      arrange(ID, date_vax) %>%
      distinct(ID, .keep_all = TRUE) %>%
      select(
        ID,
        date_birth,
        ADM1_residence,
        ADM2_residence
      )
  }
  if(!is.null(birth_cohorts)) {
    pop_table <- pop_table %>% filter(year(date_birth) %in% birth_cohorts)
  }

  # earliest date of each selected vaccine per person
  vacc_table <- .prepare_EIR_doses(data.EIR, doses_to_use, birth_cohorts) %>%
    group_by(ID, dose) %>%
    summarise(date_vax = min(date_vax), .groups = "drop") %>%
    pivot_wider(names_from = dose, values_from = date_vax)

  # vaccines nobody received still get their own (empty) column
  missing_doses <- setdiff(doses_to_use, names(vacc_table))
  vacc_table[missing_doses] <- as.Date(NA)
  vacc_table <- vacc_table %>% select(ID, all_of(doses_to_use))

  op_table <- pop_table %>%
    left_join(vacc_table, by = "ID") %>%
    mutate(
      Category = case_when(
        if_all(all_of(doses_to_use), ~ !is.na(.x)) ~ "COMPLETE",
        if_any(all_of(doses_to_use), ~ !is.na(.x)) ~ "PARTIAL",
        TRUE ~ "ZERO_DOSE"
      )
    )

  return(op_table)
}
