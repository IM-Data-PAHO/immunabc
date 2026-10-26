# (V)accination (T)imeliness Percentile Plot

Generates a range plot of the number of days since the start of the
timeliness window needed to vaccinate each percentile, with one row per
geographic area (or per dose, when `data` is not disaggregated by
geographic area). Each percentile is drawn as a point, joined by a line
from the lowest to the highest percentile. Rows are sorted by the
percentile closest to the median (P50), with the slowest areas at the
top, so the plot remains readable with many geographic areas. When
`data` is disaggregated by geographic area, the plot is faceted by
`dose`. The timeliness window of each dose is shaded.

## Usage

``` r
vt_percentile_plot(data, within_ADM1 = NULL, n_slowest = NULL)
```

## Arguments

- data:

  The output from the
  [`immunabc::vt_percentile`](https://im-data-paho.github.io/immunabc/reference/vt_percentile.md)
  function.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- n_slowest:

  Numeric (optional). Shows only this number of geographic areas, the
  ones that take the longest to reach the percentile closest to 50.
  Useful when there are many areas. Default is `NULL`, which shows all
  areas.

## Value

A ggplot object representing the percentile plot.
