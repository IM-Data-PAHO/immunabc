# (D)uplicate (D)oses Trend

This function calculates the percentage of duplicate records in the
electronic immunization registry (EIR) according to their reported month
of vaccination, further disaggregating by geographic level. It
essentially performs the same calculation as `dd_rate`, but
disaggregates by time in order to spot any possible trends. Repeated
records are not included: to explore them, use `dd_repeat_plot`.

## Usage

``` r
dd_trend(data.EIR, geo_level = "ADM0", vaccines = NULL, birth_cohorts = NULL)
```

## Arguments

- data.EIR:

  Data frame. A data frame containing individual vaccination records.
  See `immunABC.EIR` for expected structure.

- geo_level:

  Character. The geographic level to aggregate results by. Must be
  "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".

- vaccines:

  Character (optional). A character vector specifying the doses to
  include in the analysis. If `NULL` (default), all doses in `data.EIR`
  are included.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  the rate should be calculated. If `NULL` (default), all available
  cohorts are used.

## Value

A data frame with one row for each group, with the same columns as
`dd_rate`, plus `month_vax`, the first day of the month of vaccination.
The `duplication` column is always `DUPLICATE`, and is kept so the
output has the same structure as `dd_rate`.
