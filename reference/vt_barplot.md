# (V)accination (T)imeliness Barplot

Generates a bar plot showing percentage of doses administered within,
before or after the timeliness window, grouped by geographic area. If
`vt_rate` was run with `vaccines` specified, the plot is faceted by
dose.

## Usage

``` r
vt_barplot(data, within_ADM1 = NULL, plot_missing = TRUE)
```

## Arguments

- data:

  The output from the
  [`immunabc::vt_rate`](https://im-data-paho.github.io/immunabc/reference/vt_rate.md)
  function.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- plot_missing:

  Boolean (default TRUE). Plots DATE_MISSING records as its own
  category. Defaults to TRUE so all bars add to 100.

## Value

A ggplot object representing the bar plot.
