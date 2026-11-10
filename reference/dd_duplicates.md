# (D)uplicate (D)oses Records

This function returns a record-level table of the doses recorded more
than once for the same person, so they can be reviewed and corrected in
the electronic immunization registry (EIR). Each of these doses shows
all of its records, including the first one, so the later records can be
compared against it.

## Usage

``` r
dd_duplicates(data.EIR, vaccines = NULL, birth_cohorts = NULL)
```

## Arguments

- data.EIR:

  Data frame. A data frame containing individual vaccination records.
  See `immunABC.EIR` for expected structure.

- vaccines:

  Character (optional). A character vector specifying the doses to
  include. If `NULL` (default), all doses in `data.EIR` are included.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  records should be returned. If `NULL` (default), all available cohorts
  are used.

## Value

A data frame with one row per record, with the following columns:

- `ID`, `date_birth`, `dose`, `date_vax`, `ADM1_occurrence`,
  `ADM2_occurrence`.

- `group`: a unique number that identifies all records of the same
  person and dose.

- `copy`: position of the record within its group, in date order.

- `n_copies`: total number of records for that person and dose.

- `days_since_first_entry`: number of days between the record and the
  `FIRST_ENTRY` of its group (`NA` for the `FIRST_ENTRY` itself).

- `duplication`: the category of the record, one of:

  - `FIRST_ENTRY`: the first record of that person and dose, shown for
    comparison.

  - `REPEATED`: extra record with the same ID and dose as an earlier
    record, but a different date or place of occurrence. It may be a
    dose really administered twice.

  - `DUPLICATE`: extra record with the same ID, dose, vaccination date
    and place of occurrence as an earlier record.

## Details

Records missing `ID`, `dose`, `date_vax`, `ADM1_occurrence` or
`ADM2_occurrence` cannot be shown to match another record, so they are
filtered out. Please note that `NA` and empty text count as missing.
