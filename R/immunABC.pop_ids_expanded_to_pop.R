#' immunABC population individualized records
#'
#' A dataset containing personally identifying information of a population's individuals, for cross-reference with EIR records.
#' Each row represents a specific person, along with relevant geographic and demographic information.
#'
#' This dataset contains records for from people in immunABC.EIR, with made-up rows to match each year's and ADM2's birth_cohort in immunABC.pop.
#'
#' @format A data frame with X rows and 5 variables:
#' \describe{
#'   \item{ID}{A unique identifier for each person.}
#'   \item{name}{Person's name.}
#'   \item{date_birth}{The person's birth date.}
#'   \item{ADM1_residence}{The first geographic administrative level of the person's residence.}
#'   \item{ADM2_residence}{The second geographic administrative level of the person's residence.}
#' }
#' @source immunABC
"immunABC.pop_ids_expanded_to_pop"
