# (B)irth (C)ohort Coverage Bar Plot

Generates a bar plot of birth cohort coverage, grouped by geographic
area and colored by birth cohort year.

## Usage

``` r
bc_barplot(
  data,
  vaccine,
  birth_cohorts = NULL,
  within_ADM1 = NULL,
  palette = "YlOrBr"
)
```

## Arguments

- data:

  Data frame. The output from the
  [`immunabc::bc_coverage`](https://im-data-paho.github.io/immunabc/reference/bc_coverage.md)
  function.

- vaccine:

  Character. A string specifying the vaccine of interest. Only one
  vaccine.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  coverage should be plotted. If `NULL` (default), all years are
  plotted.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- palette:

  Character (optional). A RColorBrewer palette name for the cohort
  colors. Default is `"YlOrBr"`.

## Value

A ggplot object representing the bar plot.
