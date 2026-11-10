# (D)uplicate (D)oses Trend Plot

Generates a line plot of the percentage or number of duplicate records
according to their reported vaccination date, from the output of
`dd_trend`, which helps identify the vaccination months most affected.
If duplicates are high only for a few months, the records from those
months may have been entered twice, for example when moving data from an
old system into the EIR.

## Usage

``` r
dd_trend_plot(
  data,
  value = "rate",
  highlight = NULL,
  within_ADM1 = NULL,
  min_total = NULL
)
```

## Arguments

- data:

  The output from the
  [`immunabc::dd_trend`](https://im-data-paho.github.io/immunabc/reference/dd_trend.md)
  function.

- value:

  Character. What to show on the y-axis: "rate" (default), the
  percentage of records that are duplicates; or "n", their number. With
  "n", all areas combined will show the sum of all areas, so its value
  may be significantly larger than each individual area.

- highlight:

  Character (optional). Up to 5 geographic areas to highlight in color.
  Only available when `data` is disaggregated by "ADM1" or "ADM2".
  Default is `NULL`, which highlights nothing.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. All areas combined then refers to those areas only. Default is
  `NULL`, which means no filtering by "ADM1".

- min_total:

  Numeric (optional). Minimum number of records required for a line to
  be shown for a given month. This means each line may have gaps if the
  number of records was too small at a given point in time. This is
  useful because rates based on few records can be misleading and
  stretch the y-axis. Default is `NULL`, which shows all months.

## Value

A ggplot object representing the trend plot.

## Details

If `data` is disaggregated by geographic area, each area is drawn as a
thin grey line for context, and all areas combined are drawn as a single
highlighted line. Specific areas can be highlighted in color with
`highlight`. To show a single vaccine, use the `vaccines` argument of
`dd_rate`.
