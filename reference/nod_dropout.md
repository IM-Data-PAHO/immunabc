# (No)minal (D)ropout Rate

(No)minal (D)ropout Rate

## Usage

``` r
nod_dropout(
  data.EIR,
  vaccine_init,
  vaccine_end,
  geo_level = "ADM0",
  birth_cohorts = NULL,
  fix_residence = TRUE
)
```

## Arguments

- data.EIR:

  A data frame containing individual vaccination records. See
  `immunABC.EIR` for expected structure.

- vaccine_init:

  Initial vaccine to use in nominal dropout calculation.

- vaccine_end:

  Final vaccine to use in nominal dropout calculation.

- geo_level:

  The geographic level to aggregate results by. Must be "ADM0", "ADM1"
  or "ADM2". If not specified, the default is "ADM0".

- birth_cohorts:

  Birth cohorts to calculate for. As a vector of years.

- fix_residence:

  Logical. This function requires each person to have a single place of
  residence across all their vaccinations when geo_level is "ADM1" or
  "ADM2". When a person has more than one residence, TRUE (default) sets
  all their records to the residence of their most recent vaccination,
  and FALSE stops with an error.

## Value

A data frame with two rows per geographic unit of residence: one for
people who received `vaccine_init` but not `vaccine_end` (dropout) and
one for people who received both (complete). People without
`vaccine_init` are not counted. Columns:

- `ADM1_residence`, `ADM2_residence`: geographic unit of residence (will
  only appear depending on what is set in `geo_level`).

- `indicator`: A category: either `"dropout"` or `"complete"`.

- `num`: number of people in that category.

- `denom`: number of people who received `vaccine_init`.

- `percent`: `num / denom * 100`.
