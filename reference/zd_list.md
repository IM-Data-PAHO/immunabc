# (Z)ero (D)ose List

This function lists each person with the date of each of a given set of
vaccines, using data from the electronic immunization registry (EIR),
and classifies them by how many of those vaccines they have received.

## Usage

``` r
zd_list(data.EIR, vaccines = NULL, birth_cohorts = NULL, data.pop_ids = NULL)
```

## Arguments

- data.EIR:

  Data frame. A data frame containing individual vaccination records.
  See `immunABC.EIR` for expected structure.

- vaccines:

  Character (optional). A character vector specifying the doses to
  include in the analysis. If `NULL` (default), all vaccines in
  `data.EIR` are included.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) of the
  people to list. If `NULL` (default), every person is listed regardless
  of birth year.

- data.pop_ids:

  Data frame (optional). A data frame with individual population records
  (such as a civil registry) that can be cross-referenced with the EIR.
  See `immunABC.pop_ids` for expected structure. If provided, every
  person in it is listed, plus the people in `data.EIR` whose `ID` is
  not in it, with no `name`. A warning reports how many of these people
  there are.

## Value

A data frame with one row per person, the earliest date of each of the
`vaccines` and a `Category` column: "COMPLETE" if the person has all of
them, "PARTIAL" if they have some, and "ZERO_DOSE" if they have none.
When `data.pop_ids` is provided, it also includes `name` and a `Source`
column: "POP_IDS" for people in `data.pop_ids`, and "EIR_ONLY" for
people only found in `data.EIR`, whose residence and date of birth come
from their earliest EIR record.
