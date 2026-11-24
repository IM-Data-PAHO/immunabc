# immunABC population individualized records

A dataset containing personally identifying information of a
population's individuals, for cross-reference with EIR records. Each row
represents a specific person, along with relevant geographic and
demographic information.

## Usage

``` r
immunABC.pop_ids_expanded_to_pop
```

## Format

A data frame with X rows and 5 variables:

- ID:

  A unique identifier for each person.

- name:

  Person's name.

- date_birth:

  The person's birth date.

- ADM1_residence:

  The first geographic administrative level of the person's residence.

- ADM2_residence:

  The second geographic administrative level of the person's residence.

## Source

immunABC

## Details

This dataset contains records for from people in immunABC.EIR, with
made-up rows to match each year's and ADM2's birth_cohort in
immunABC.pop.
