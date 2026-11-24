# (Z)ero (D)ose Rate Bar Plot

Generates a bar plot of the zero-dose rate, grouped by geographic area
and colored by birth cohort year. When several vaccines are plotted,
each one is shown in its own panel.

## Usage

``` r
zd_barplot(
  data,
  vaccine = NULL,
  birth_cohorts = NULL,
  within_ADM1 = NULL,
  palette = "YlOrBr"
)
```

## Arguments

- data:

  Data frame. The output from the
  [`immunabc::zd_rate`](https://im-data-paho.github.io/immunabc/reference/zd_rate.md)
  function.

- vaccine:

  Character (optional). A vector specifying the vaccine(s) to plot, one
  panel per vaccine. If `NULL` (default), the combined "All" rate is
  plotted when present in `data` (that is, when `zd_rate` was run
  without `vaccines`); otherwise every vaccine in `data` is plotted.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) to plot.
  If `NULL` (default), all years are plotted.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- palette:

  Character (optional). A RColorBrewer palette name for the cohort
  colors. Default is `"YlOrBr"`.

## Value

A ggplot object representing the bar plot. Negative zero-dose rates
(more vaccinated people than population) are drawn as their absolute
value with a red outline.
