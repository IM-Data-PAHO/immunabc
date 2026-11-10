# (D)uplicate (D)oses Repeat Plot

Generates two histograms comparing the age of vaccination of records
identified as `REPEATED`. Shows the age at vaccination of the
`FIRST_ENTRY`s in one histogram, while showing the age at vaccination of
the `REPEATED` records in the other. Comparing both helps tell apart the
possible causes of repeats: for example, if the repeats of DTP1 are
concentrated at the age when DTP2 is due, then the "DTP1" dose may have
been registered with the wrong dose number.

## Usage

``` r
dd_repeat_plot(
  data,
  vaccine,
  geo_level = "ADM0",
  within_ADM1 = NULL,
  binwidth = 7,
  max_age = NULL,
  data.schedule = NULL,
  schedule_vaccines = NULL
)
```

## Arguments

- data:

  The output from the
  [`immunabc::dd_duplicates`](https://im-data-paho.github.io/immunabc/reference/dd_duplicates.md)
  function.

- vaccine:

  Character. The single dose to show, e.g. "DTP1".

- geo_level:

  Character. The geographic level of occurrence to split the panels by.
  Must be "ADM0" (default, no split), "ADM1" or "ADM2".

- within_ADM1:

  Character (optional). A character vector of one or several "ADM1"
  areas of occurrence to filter. Default is `NULL`, which means no
  filtering by "ADM1".

- binwidth:

  Numeric. Width of each bar of the histogram, in days. Default is 7
  (one week).

- max_age:

  Numeric (optional). Maximum age at vaccination, in days, to show on
  the x-axis. Records after that are not shown but their number is given
  in the caption. Default is `NULL`, which shows all ages.

- data.schedule:

  Data frame (optional). A data frame defining the vaccination schedule,
  used to show the vaccination window of the doses in
  `schedule_vaccines`. See `immunABC.schedule` for expected structure.
  Default is `NULL`, which shows no schedule.

- schedule_vaccines:

  Character (optional). Up to 3 doses whose vaccination window is
  highlighted, e.g. `c("DTP1", "DTP2")`. Only used with `data.schedule`.
  If `NULL` (default), the vaccination window of `vaccine` is
  highlighted.

## Value

A ggplot object representing the histogram.

## Details

When the user provides `data.schedule`, a shaded area highlights the
vaccination window of each dose in `schedule_vaccines` (using
`age_schedule_low` and `age_schedule_high`). Results can also be split
into columns of panels per geographic area of occurrence with
`geo_level`.

Records with no `date_birth` have no age at vaccination, and records
with `date_vax` before `date_birth` have a negative one, so both are
filtered out, with a message.
