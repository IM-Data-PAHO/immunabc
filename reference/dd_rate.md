# (D)uplicate (D)oses Rate

This function calculates the percentage of records in the electronic
immunization registry (EIR) that are duplicate doses, that is, doses
entered more than once by mistake, as opposed to programmatic errors
where a dose is really administered twice. Results can be disaggregated
by geographic level and by one additional variable.

## Usage

``` r
dd_rate(
  data.EIR,
  geo_level = "ADM0",
  disaggregate_by = NULL,
  vaccines = NULL,
  birth_cohorts = NULL
)
```

## Arguments

- data.EIR:

  Data frame. A data frame containing individual vaccination records.
  See `immunABC.EIR` for expected structure.

- geo_level:

  Character. The geographic level to aggregate results by. Must be
  "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".

- disaggregate_by:

  Character (optional). One additional variable to disaggregate results
  by: "dose" or "birth_cohort" (year of birth). If `NULL` (default),
  there is no additional disaggregation.

- vaccines:

  Character (optional). A character vector specifying the doses to
  include in the analysis. This is only a filter: use
  `disaggregate_by = "dose"` to disaggregate results by dose. If `NULL`
  (default), all doses in `data.EIR` are included.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  the rate should be calculated. This is only a filter: use
  `disaggregate_by = "birth_cohort"` to disaggregate results by cohort.
  If `NULL` (default), all available cohorts are used.

## Value

A data frame with one row for each `duplication` category in each group,
with the following columns:

- `ADM1`, `ADM2`: the geographic area of occurrence, depending on
  `geo_level`.

- `dose` or `birth_cohort`: depending on `disaggregate_by`.

- `duplication`: the category of each record, one of:

  - `DUPLICATE`: a duplicate record because all the columns match (ID,
    dose, vaccination date and place of ocurrence).

  - `REPEATED`: a repeated dose where only the ID and dose match, but
    the date of vaccination or the place of ocurrence are different. May
    be caused by programmatic errors or by data entry errors.

- `n`: number of records in that category.

- `total`: total number of evaluated records in the group.

- `rate`: percentage of records in that category (`n / total * 100`).

## Details

Records of the same person and dose are compared in date order. The
first one is not counted, since it is considered the legitimate record,
and each later one is classified as either `DUPLICATE` or `REPEATED`.
Only extra records are counted, so a dose registered three times counts
as two. For example, the same dose registered 3 times, once on January
5, another on February 10 and once again on February 10 would count as:

- January 5: First dose, assumed to be legitimate.

- February 10: `REPEATED` dose, because it is the same dose on a
  different date.

- February 10: `DUPLICATE` dose, because it is registered on the same
  date as the previous.

Records missing `ID`, `dose`, `date_vax`, `ADM1_occurrence` or
`ADM2_occurrence` do not contain sufficient information to determine if
they are `DUPLICATE` or `REPEATED`, so they are filtered out. `NA` and
empty or whitespace-only text count as missing. When using
`disaggregate_by = "birth_cohort"`, records with no `date_birth` are
also filtered out, with a message. Finally, please note that in this
analysis, geographic areas always refer to the place of occurrence of
the vaccination event.
