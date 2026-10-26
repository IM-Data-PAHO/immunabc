# (C)omplete (S)chedule Coverage Bar Plot

Generates a bar plot of complete schedule vaccination coverage, grouped
by geographic area and colored by birth cohort.

## Usage

``` r
cs_barplot(data, birth_cohorts = NULL, within_ADM1 = NULL)
```

## Arguments

- data:

  The output from the
  [`immunabc::cs_coverage`](https://im-data-paho.github.io/immunabc/reference/cs_coverage.md)
  function.

- birth_cohorts:

  Numeric (optional). A vector specifying the birth cohort(s) for which
  coverage should be plotted. If `NULL` (default), all years are
  plotted.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

## Value

A ggplot object representing the bar plot.
