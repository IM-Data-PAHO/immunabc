# Using our Example Datasets

[🌐 Lea esto en
español](https://im-data-paho.github.io/immunabc/articles/es/example_datasets_es.md)

## Rationale

The immunABC package includes a set of example datasets to help users
understand how to use its functions effectively. These datasets simulate
a fictional country’s immunization information system and are structured
to work seamlessly with the tools provided by the package. This vignette
provides an overview of each dataset and describes how they are used
throughout the package’s modules.

## Glossary

### Political Geographic Boundaries

Throughout this vignette, we will make reference to different levels of
political geographic boundaries. These levels are defined by the
country/territory and can have different names from country to country.
immunABC is agnostic to these names and requires the user to recode
their variable names to fit the immunABC structure.

Namely, immunABC can distinguish three administrative levels, which
listed from top to bottom level are: ADM0, ADM1 and ADM2.

1.  ADM0: The country. This is the top-most administrative level.
2.  ADM1: The first geographic subdivision in the country. ADM0 contains
    several ADM1 subdivisions.
3.  ADM2: The second geographic subdivision in the country. Each ADM1
    contains several ADM2 subdivisions.

![](ADM_explanation.svg)

### Vaccine Names

Our example datasets use a specific naming convention for the vaccine
doses. This might not match your own naming schemes, but it will not
affect the usage of the package as long as you make sure to be
consistent when naming vaccine doses.

For example, the vaccine names used in the immunABC example datasets
are:

| Abbreviation | Full Name                                             |
|--------------|-------------------------------------------------------|
| SRP1         | Measles, Rubella, and Mumps Vaccine (1st dose)        |
| DTP1         | Diphtheria, Tetanus, and Pertussis Vaccine (1st dose) |
| DTP2         | Diphtheria, Tetanus, and Pertussis Vaccine (2nd dose) |
| DTP3         | Diphtheria, Tetanus, and Pertussis Vaccine (3rd dose) |
| BCG RN       | Bacillus Calmette–Guérin Vaccine (at birth)           |
| YFV1         | Yellow Fever Vaccine (1st dose)                       |

## List of example datasets

### immunABC.EIR

The
[`immunabc::immunABC.EIR`](https://im-data-paho.github.io/immunabc/reference/immunABC.EIR.md)
dataframe is the most important dataset in the package. It is a
nominal-level table representing individual vaccination events from an
Electronic Immunization Registry (EIR). Each row corresponds to a single
vaccination act for a person, including information on their residence,
where they were vaccinated, their date of birth, and the vaccine dose
received.

``` r

immunABC.EIR %>% head() %>% kable(caption = "Example Electronic Immunization Registry")
```

| ID | date_birth | date_vax | ADM1_residence | ADM2_residence | ADM1_occurrence | ADM2_occurrence | dose |
|---:|:---|:---|:---|:---|:---|:---|:---|
| 191997 | 2023-08-08 | 2023-12-26 | ADM1_4 | ADM2_4_35 | ADM1_4 | ADM2_4_35 | DTP2 |
| 212189 | 2023-12-20 | 2023-12-26 | ADM1_5 | ADM2_5_61 | ADM1_5 | ADM2_5_61 | BCG RN |
| 118063 | 2022-09-15 | 2023-12-26 | ADM1_2 | ADM2_2_5 | ADM1_2 | ADM2_2_5 | DTP1 |
| 118063 | 2022-09-15 | 2023-12-26 | ADM1_2 | ADM2_2_5 | ADM1_2 | ADM2_2_5 | YFV1 |
| 130751 | 2022-10-27 | 2023-12-12 | ADM1_5 | ADM2_5_55 | ADM1_5 | ADM2_5_55 | YFV1 |
| 136532 | 2021-09-21 | 2023-12-26 | ADM1_3 | ADM2_3_12 | ADM1_3 | ADM2_3_12 | SRP1 |

Example Electronic Immunization Registry {.table style="width:100%;"}

- `ID`: Unique person identification number.
- `date_birth`: Date of birth of person.
- `date_vax`: Date of vaccination event.
- ADM1: Refers to the first geographic administrative level of the
  country.
- ADM2: Refers to the second geographic administrative level of the
  country.
- Residence: Refers to the place where the person lives.  
- Occurrence: Refers to the place where the vaccination event
  occurred.  
- `dose`: A combined variable representing the vaccine type and its
  corresponding dose number. For example, DTP1 refers to the first dose
  of a vaccine containing diphtheria, tetanus, and pertussis components.

### immunABC.schedule

The
[`immunabc::immunABC.schedule`](https://im-data-paho.github.io/immunabc/reference/immunABC.schedule.md)
dataset defines the national immunization schedule, listing each vaccine
dose and its recommended age of administration (in days). It helps the
package determine whether an individual is up to date with their
vaccinations.

``` r

immunABC.schedule %>% kable(caption = "Example Immunization Schedule")
```

| dose   | age_schedule | age_schedule_low | age_schedule_high |
|:-------|-------------:|-----------------:|------------------:|
| SRP1   |          365 |              360 |               420 |
| DTP1   |           60 |               54 |                90 |
| DTP2   |          120 |              116 |               150 |
| DTP3   |          180 |              176 |               210 |
| BCG RN |            0 |                0 |                28 |
| YFV1   |          365 |              360 |               420 |

Example Immunization Schedule {.table}

- `dose`: A combined variable representing the vaccine type and its
  corresponding dose number. For example, DTP1 refers to the first dose
  of a vaccine containing diphtheria, tetanus, and pertussis components.
- `age_schedule`: The recommended age of administration of the
  corresponding `dose` in days.
- `age_schedule_low`: The lower limit for the target age in days.
- `age_schedule_high`: The upper limit for the target age in days.

> **Note**
>
> The `dose` names must match exactly those in the `dose` column of the
> `immunABC.EIR` dataset.

### Population Datasets

Population datasets provide population estimates at different geographic
levels, for various years and children of varying ages. Depending on the
geographic level at which we want to perform an analysis, immunABC may
require you to provide the corresponding population to use as a
denominator (mainly for coverage analyses).

#### immunABC.pop.ADM0

The
[`immunabc::immunABC.pop.ADM0`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop.ADM0.md)
dataset provides aggregated population estimates at the national level
(ADM0).

``` r

immunABC.pop.ADM0 %>% kable(caption = "Example Population at ADM0")
```

| year | age | population |
|-----:|----:|-----------:|
| 2022 |   0 |   45846.71 |
| 2022 |   1 |   48268.88 |
| 2023 |   0 |   45445.28 |
| 2023 |   1 |   47828.03 |

Example Population at ADM0 {.table}

This table is in long format and contains the corresponding `population`
of children of a specific `age` during a given `year`.

#### immunABC.pop.ADM1

The
[`immunabc::immunABC.pop.ADM1`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop.ADM1.md)
dataset provides population data aggregated at the first subnational
administrative level (ADM1), typically corresponding to regions,
provinces, or states.

``` r

immunABC.pop.ADM1 %>% head() %>% kable(caption = "Example Population at ADM1")
```

| ADM1   | year | age | population |
|:-------|-----:|----:|-----------:|
| ADM1_1 | 2022 |   0 |   1718.189 |
| ADM1_1 | 2022 |   1 |   1808.964 |
| ADM1_1 | 2023 |   0 |   1703.145 |
| ADM1_1 | 2023 |   1 |   1792.443 |
| ADM1_2 | 2022 |   0 |   6575.261 |
| ADM1_2 | 2022 |   1 |   6922.644 |

Example Population at ADM1 {.table}

Note that this table is in long format and contains the corresponding
`population` of children of a specific `age` during a given `year` at
the `ADM1` level.

#### immunABC.pop.ADM2

The
[`immunabc::immunABC.pop.ADM2`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop.ADM2.md)
dataset provides more granular population data by both ADM1 and ADM2
levels, allowing analyses at a finer geographic resolution.

``` r

immunABC.pop.ADM2 %>% head() %>% kable(caption = "Example Population at ADM2")
```

| ADM1   | ADM2      | year | age | population |
|:-------|:----------|-----:|----:|-----------:|
| ADM1_4 | ADM2_4_29 | 2022 |   0 |   755.3488 |
| ADM1_4 | ADM2_4_29 | 2022 |   1 |   795.2554 |
| ADM1_4 | ADM2_4_26 | 2022 |   0 |   225.9325 |
| ADM1_4 | ADM2_4_26 | 2022 |   1 |   237.8689 |
| ADM1_4 | ADM2_4_27 | 2022 |   0 |   356.0747 |
| ADM1_4 | ADM2_4_27 | 2022 |   1 |   374.8869 |

Example Population at ADM2 {.table}

Note that this table is in long format and contains the corresponding
`population` of children of a specific `age` during a given `year` at
the `ADM2` level.

### Individual Population Records

Unlike the population datasets above, which hold aggregated estimates,
individual population records hold one row per person, as in a civil
registry or a census. Since each row is a person, they can be
cross-referenced with the EIR through the `ID` column to find the people
with no vaccination records and list each of them (mainly for zero-dose
analyses).

Both datasets share the same columns:

- `ID`: Unique person identification number. It must match the `ID` used
  in the EIR.
- `name`: Name of the person.
- `date_birth`: Date of birth of person.
- `ADM1_residence` / `ADM2_residence`: First and second geographic
  administrative levels of the person’s residence.

#### immunABC.pop_ids

The
[`immunabc::immunABC.pop_ids`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop_ids.md)
dataset contains exactly the same people as `immunABC.EIR`, one row per
person. Since every person in it has at least one vaccination record, it
is useful as a baseline for tests.

``` r

immunABC.pop_ids %>% head() %>% kable(caption = "Example Individual Population Records")
```

| ID | date_birth | ADM1_residence | ADM2_residence | name |
|---:|:---|:---|:---|:---|
| 1 | 2013-12-14 | ADM1_2 | ADM2_2_5 | Dion Rodriguez-Martinez Romo-Hernandez |
| 2 | 1998-12-21 | ADM1_3 | ADM2_3_8 | Henry Hernandez Contreras |
| 3 | 1986-12-02 | ADM1_3 | ADM2_3_16 | Moses Torres Martinez |
| 4 | 1986-06-07 | ADM1_3 | ADM2_3_17 | Keylian Saldana Wilson-Sandoval |
| 5 | 1958-09-10 | ADM1_3 | ADM2_3_13 | Berenise Salazar Bautista Rubio |
| 6 | 2017-09-18 | ADM1_2 | ADM2_2_5 | Rocela Cazares Medina |

Example Individual Population Records {.table}

#### immunABC.pop_ids_expanded_to_pop

The
[`immunabc::immunABC.pop_ids_expanded_to_pop`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop_ids_expanded_to_pop.md)
dataset contains every person in `immunABC.EIR`, plus simulated people
with no vaccination records, so that each birth cohort matches the
population in `immunABC.pop.ADM2`.

``` r

immunABC.pop_ids_expanded_to_pop %>% head() %>% kable(caption = "Example Individual Population Records Expanded to Population")
```

|  ID | date_birth | ADM1_residence | ADM2_residence | name                            |
|----:|:-----------|:---------------|:---------------|:--------------------------------|
|   1 | 2013-12-14 | ADM1_2         | ADM2_2_5       | Dion Rodriguez Romo             |
|   2 | 1998-12-21 | ADM1_3         | ADM2_3_8       | Henry Hernandez Contreras       |
|   3 | 1986-12-02 | ADM1_3         | ADM2_3_16      | Moses Torres Martinez           |
|   4 | 1986-06-07 | ADM1_3         | ADM2_3_17      | Keylian Saldana Wilson          |
|   5 | 1958-09-10 | ADM1_3         | ADM2_3_13      | Berenise Salazar Bautista Rubio |
|   6 | 2017-09-18 | ADM1_2         | ADM2_2_5       | Rocela Cazares Medina           |

Example Individual Population Records Expanded to Population {.table}

> **Note**
>
> The simulated people with no vaccination records were only added to
> the 2022 and 2023 birth cohorts, since the example population tables
> only hold the population of those two birth cohorts. People born in
> any other year come only from the EIR, so all of them have at least
> one vaccination record.

## Summary

All example datasets are loaded automatically with the package. You can
explore their structure using `glimpse()` or
[`View()`](https://rdrr.io/r/utils/View.html). They are designed to work
seamlessly with the default arguments in all functions, allowing you to
test and understand each module with minimal setup.

Here is a summary of the available datasets for your reference.

| Dataset | Description |
|----|----|
| `immunABC.EIR` | Electronic Immunization Registry |
| `immunABC.schedule` | Vaccination schedule with dose names and ages |
| `immunABC.pop.ADM0` | Aggregated national-level population estimates |
| `immunABC.pop.ADM1` | ADM1-level population estimates |
| `immunABC.pop.ADM2` | ADM2-level population estimates |
| `immunABC.pop_ids` | Individual population records of the people in the EIR |
| `immunABC.pop_ids_expanded_to_pop` | Individual population records expanded to match `immunABC.pop.ADM2` |
