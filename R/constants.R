#' Columns of data.EIR required by the date consistency comparison (dcc_) module.
#'
#' @keywords internal
#' @noRd
.dcc_required_cols <- c("ID", "ADM1_residence", "ADM2_residence", "dose")

#' Key columns of the duplicate doses (dd_) module used to compare duplicate records.
#'
#' @keywords internal
#' @noRd
.dd_key_cols <- c("ID", "dose", "date_vax", "ADM1_occurrence", "ADM2_occurrence")

#' Columns of data.EIR required by the duplicate doses (dd_) module.
#'
#' @keywords internal
#' @noRd
.dd_required_cols <- c(.dd_key_cols, "date_birth")
