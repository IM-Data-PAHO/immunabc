# (D)uplicate (D)oses Barplot

Generates a bar plot of duplicate (or repeated) records from the output
of `dd_rate`, showing either their percentage or their number. The
disaggregations are detected from `data`: geographic areas go on the
x-axis if present, otherwise doses or birth cohorts, and `dose` or
`birth_cohort` become panels when `data` also has geographic areas.

## Usage

``` r
dd_barplot(
  data,
  value = "rate",
  duplication = "duplicate",
  within_ADM1 = NULL,
  min_total = NULL
)
```

## Arguments

- data:

  The output from the
  [`immunabc::dd_rate`](https://im-data-paho.github.io/immunabc/reference/dd_rate.md)
  function.

- value:

  Character. What to show on the y-axis: "rate" (default), the
  percentage of records in the `duplication` category, which shows where
  the problem is proportionally worst; or "n", their number, which shows
  where most records need correcting.

- duplication:

  Character. Which records to show: "duplicate" (default), the extra
  records with the same person, dose, vaccination date and place of
  occurrence as an earlier record, which is the indicator; or
  "repeated", the extra records with the same person and dose but a
  different date or place.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- min_total:

  Numeric (optional). Minimum number of records for a bar to be shown,
  since rates based on few records can be misleading. Hidden bars still
  count towards the dashed line. Default is `NULL`, which shows all
  bars.

## Value

A ggplot object representing the bar plot.

## Details

The y-axis is scaled to the data instead of 0 to 100, since duplicate
records are usually a small percentage of all records. When showing
rates, a dashed line shows the rate of all groups combined.
