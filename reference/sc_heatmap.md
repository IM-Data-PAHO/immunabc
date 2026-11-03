# Dose (S)equence (C)omparison Heatmap

Generates a heatmap showing how people are distributed across the
combinations of doses received of an ordered dose sequence (e.g. DTP1,
DTP2 and DTP3), for each geographic area of residence, using data from
the electronic immunization registry (EIR).

## Usage

``` r
sc_heatmap(
  data.EIR,
  vaccines,
  geo_level = "ADM0",
  show_consistent = TRUE,
  within_ADM1 = NULL,
  birth_cohorts = NULL,
  allow_same_day = FALSE,
  fix_residence = TRUE,
  digits = 0
)
```

## Arguments

- data.EIR:

  Data frame. A data frame containing individual vaccination records.
  See `immunABC.EIR` for expected structure.

- vaccines:

  Character. A character vector of at least two doses with the ordered
  dose sequence to evaluate, e.g. `c("DTP1", "DTP2", "DTP3")`.

- geo_level:

  Character. The geographic level of residence to show as columns. Must
  be "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".

- show_consistent:

  Logical. Whether to show consistent and `DATE_MISSING` sequences, with
  percentages over all people in each area (TRUE, default), or only
  inconsistent sequences, with percentages over the inconsistent
  sequences in each area (FALSE).

- within_ADM1:

  Character (optional). This optional character vector lets you specify
  one or several "ADM1" to filter. Default is `NULL`, which means no
  filtering by "ADM1".

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) to
  evaluate. If `NULL` (default), all available cohorts are used.

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

- digits:

  The number of digits to show in the labels. Default is 0.

## Value

A ggplot object representing the heatmap.

## Details

Rows are split into consistent sequences (no dose skipped and doses in
chronological order, e.g. "DTP1", "DTP1 + DTP2", "DTP1 + DTP2 + DTP3"),
`DATE_MISSING` sequences and inconsistent sequences (e.g. "DTP1 + DTP3",
or "DTP1 + DTP2 (out of order)" when the doses were not administered in
chronological order). By default (`show_consistent = TRUE`), percentages
are calculated over all people with at least one dose of the sequence in
each area, so inconsistent sequences can be compared against the
consistent ones. Set `show_consistent = FALSE` to hide consistent and
`DATE_MISSING` sequences and deep dive into the inconsistent ones:
percentages are then recalculated over the inconsistent sequences of
each area only.

Only people with at least one dose of the sequence are evaluated. Since
this is a nominal indicator, each person is assigned to a single place
of residence (see `fix_residence`).
