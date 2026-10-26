# (V)accination (T)imeliness Probability Distribution Plot

Generates a plot of the percentage vaccinated on each day since the
start of the timeliness window, faceted by `dose`.

## Usage

``` r
vt_pdf_plot(
  data,
  percentile = NULL,
  highlight = NULL,
  within_ADM1 = NULL,
  max_days = NULL,
  binwidth = 1,
  x_axis = "absolute"
)
```

## Arguments

- data:

  The output from the
  [`immunabc::vt_distribution`](https://im-data-paho.github.io/immunabc/reference/vt_distribution.md)
  function.

- percentile:

  Numeric (optional). A single percentile (greater than 0 and at
  most 100) to highlight in the plot. This is inserted as a label for
  all highlighted areas and for the combined plot. Default is `NULL`,
  which highlights nothing.

- highlight:

  Character (optional). Up to 5 geographic areas to highlight in color.
  Only available when `data` is disaggregated by "ADM1" or "ADM2".
  Default is `NULL`, which highlights nothing.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- max_days:

  Numeric (optional). Maximum number of days since the start of the
  timeliness window to show on the x-axis, useful to trim long tails of
  late vaccinations. Default is `NULL`, which shows up to the day at
  which 95% of records are vaccinated.

- binwidth:

  Numeric (optional). Provide a number of days to be grouped for each
  data point in the graph. Default is 1.

- x_axis:

  Character. Either "absolute" (default), where the x-axis shows the age
  at vaccination in days, starting at the `age_schedule_low` of each
  dose; or "relative", where the x-axis shows the days since the start
  of the timeliness window, starting at 0 for every dose.

## Value

A ggplot object representing the probability distribution plot.

## Details

The timeliness window of each dose is shaded. If `data` is disaggregated
by geographic area, each area is drawn as a thin grey line for context,
and all areas combined are drawn as a single highlighted line. Specific
areas can be highlighted in color with `highlight`. Records vaccinated
before the timeliness window and records with a missing date are
excluded from the distribution and reported in the caption.

When showing several subnational areas, the y-axis is limited to the
range of the highlighted lines, so any gray lines outside those limits
are cut.
