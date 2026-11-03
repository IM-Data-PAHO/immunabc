# Dose (S)equence (C)omparison Rate

This function checks, for each person, whether the doses they received
of an ordered dose sequence (e.g. DTP1, DTP2 and DTP3) are consistent,
and calculates the percentage of consistent and inconsistent sequences,
further disaggregating by geographic level of residence, using data from
the electronic immunization registry (EIR).

## Usage

``` r
sc_rate(
  data.EIR,
  vaccines,
  geo_level = "ADM0",
  aggregated = TRUE,
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

- geo_level:

  Character. The geographic level to aggregate results by. Must be
  "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".

- aggregated:

  Logical. Whether to pool all inconsistent sequences into a single
  `INCONSISTENT` category (TRUE, default), or keep `CONSISTENT` as a
  single category and show every inconsistent combination of doses
  received (FALSE), e.g. `"DTP1 + DTP3"`, flagging the ones administered
  out of chronological order (e.g. `"DTP1 + DTP2 (out of order)"`).

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  the rate should be calculated. If `NULL` (default), all available
  cohorts are used.

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

A data frame with one row per `sequence` category for the specified
`geo_level`, with the following columns:

- `sequence`: the category of each sequence, one of:

  - `CONSISTENT`: no dose skipped and every dose administered in
    chronological order.

  - `INCONSISTENT` (only when `aggregated = TRUE`): a dose was skipped
    and/or administered out of chronological order. When
    `aggregated = FALSE`, inconsistent sequences are shown as the
    combination of doses received, e.g. `"DTP1 + DTP3"` (missing DTP2),
    with the suffix `" (out of order)"` when the doses were not
    administered in chronological order.

  - `DATE_MISSING`: no dose skipped and no chronological inconsistency
    found, but at least one dose received has no `date_vax`, so the
    chronological order cannot be fully evaluated.

- `consistent`: whether that category corresponds to a consistent
  sequence (`NA` for `DATE_MISSING`).

- `n`: number of people in that category.

- `total`: total number of people with at least one dose of the
  sequence.

- `rate`: percentage of people in that category (`n / total * 100`).

## Details

A sequence is consistent when both of the following hold:

- No earlier dose is skipped, i.e. the doses received are the first
  doses of the sequence. For a DTP1, DTP2, DTP3 sequence, "DTP1",
  "DTP1 + DTP2" and "DTP1 + DTP2 + DTP3" pass this check (the person may
  simply not have finished the sequence yet), while "DTP2", "DTP3",
  "DTP1 + DTP3" and "DTP2 + DTP3" do not.

- The doses received were administered in chronological order, i.e. each
  dose after the previous dose received in the sequence (e.g. DTP2 after
  DTP1).

Only people with at least one dose of the sequence are evaluated. Since
this is a nominal indicator, each person is assigned to a single place
of residence (see `fix_residence`).
