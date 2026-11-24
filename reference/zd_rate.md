# (Z)ero (D)ose Rate

This function computes the proportion of people that have no record of
receiving a given set of vaccines using data from the electronic
immunization registry (EIR).

## Usage

``` r
zd_rate(
  data.EIR,
  geo_level = "ADM0",
  vaccines = NULL,
  birth_cohorts = NULL,
  data.pop = NULL,
  data.pop_ids = NULL,
  fix_residence = TRUE
)
```

## Arguments

- data.EIR:

  Data frame. A data frame containing individual vaccination records.
  See `immunABC.EIR` for expected structure.

- geo_level:

  Character. The geographic level to aggregate results by. Must be
  "ADM0", "ADM1" or "ADM2". If not specified, the default is "ADM0".
  Note also that if `data.pop` is in use, it must contain the columns to
  match.

- vaccines:

  Character (optional). A character vector specifying the doses to
  include in the analysis. If `NULL` (default), all vaccines in
  `data.EIR` are included.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  the zero-dose rate should be calculated. If `NULL` (default), every
  person is included regardless of birth year. With `data.pop`, this
  also means every year in the population table; years with no records
  in `data.EIR` will show a zero-dose rate of 100.

- data.pop:

  Data frame (optional). A data frame with population denominators. See
  `immunABC.pop.ADMX` for structure examples. If `NULL` (default) and no
  `data.pop_ids` is provided, the denominator is computed from
  `data.EIR`.

- data.pop_ids:

  Data frame (optional). A data frame with individual population records
  (such as a civil registry) that can be cross-referenced with the EIR.
  See `immunABC.pop_ids` for expected structure. If provided,
  denominators are computed from it instead of `data.pop` or `data.EIR`.
  Its residence is never modified: when geo_level is "ADM1" or "ADM2", a
  warning reports the people whose residence differs from their
  residence in `data.EIR`, which should be corrected before running the
  analysis.

- fix_residence:

  Logical. This function requires each person in `data.EIR` to have a
  single place of residence across all their vaccinations when geo_level
  is "ADM1" or "ADM2", so that each person is counted in a single area.
  When a person has more than one residence, TRUE (default) sets all
  their records to the residence of their most recent vaccination, and
  FALSE stops with an error.

## Value

A data frame containing the zero-dose rate for each of the `vaccines`,
birth cohort and geographic area, including groups where nobody was
vaccinated. When `vaccines` is `NULL`, it also contains rows with `dose`
"All", counting as vaccinated the people with at least one vaccine. A
warning is raised when a group has more vaccinated people than
population (negative `zd_rate`). To list each person and their vaccines,
see `zd_list`.
