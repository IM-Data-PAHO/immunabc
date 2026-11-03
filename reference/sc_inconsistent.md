# Dose (S)equence (C)omparison Inconsistent Records

This function returns a person-level table of all inconsistent dose
sequences (sequences where an earlier dose is skipped, e.g. DTP1 + DTP3,
and/or where the doses were not administered in chronological order,
e.g. DTP2 before DTP1), in a schedule-like format: one row per person
and one column per dose of the sequence, containing the date the dose
was administered.

## Usage

``` r
sc_inconsistent(
  data.EIR,
  vaccines,
  birth_cohorts = NULL,
  allow_same_day = FALSE,
  fix_residence = TRUE
)
```

## Arguments

- data.EIR:

  Data frame. A data frame containing individual vaccination records.
  See `immunABC.EIR` for expected structure.

- vaccines:

  Character. A character vector of at least two doses with the ordered
  dose sequence to evaluate, e.g. `c("DTP1", "DTP2", "DTP3")`.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  inconsistent sequences should be returned. If `NULL` (default), all
  available cohorts are used.

- allow_same_day:

  Logical. Whether two consecutive doses administered on the same day
  are considered chronologically consistent. Default is `FALSE`, since
  doses of the same vaccine series should not be administered on the
  same day.

- fix_residence:

  Logical. When a person's residence differs across their records,
  whether to correct all of that person's records to the residence of
  their most recent vaccination (TRUE, default) or leave the data as-is
  (FALSE), in which case each person is assigned the residence of their
  first record.

## Value

A data frame with one row per person with an inconsistent sequence, with
the following columns:

- `ID`: unique person identification number.

- `date_birth`: date of birth.

- `ADM1_residence`, `ADM2_residence`: place of residence.

- One column per dose in `vaccines`, in the order of the sequence: the
  date the dose was administered (the earliest one, if duplicated), or
  `NA` if it was not received (or was received with no `date_vax`).

- `sequence`: the combination of doses received, e.g. `"DTP1 + DTP3"`.

- `skipped_doses`: the doses of the sequence skipped, i.e. not received
  but followed by a dose that was received, e.g. `"DTP2"` for
  `"DTP1 + DTP3"`. `NA` if no dose was skipped.

- `out_of_order`: whether the doses received were not administered in
  chronological order.

## Details

Only people with at least one dose of the sequence are evaluated. Since
this is a nominal indicator, each person is assigned to a single place
of residence (see `fix_residence`).
