# (V)accination (T)imeliness Percentiles

This function calculates the number of days since the start of the
timeliness window needed to vaccinate a given percentage of the analyzed
records, for each `dose` and geographic area present in `data`.

## Usage

``` r
vt_percentile(data, percentiles = c(25, 50, 75))
```

## Arguments

- data:

  The output from the
  [`immunabc::vt_distribution`](https://im-data-paho.github.io/immunabc/reference/vt_distribution.md)
  function. The disaggregation is inherited from this data.

- percentiles:

  Numeric. A vector of percentiles (greater than 0 and at most 100) to
  calculate. Default is `c(25, 50, 75)`.

## Value

A data frame with one row per `percentile` for each `dose` and
geographic area, with the following columns:

- `percentile`: the percentile.

- `day`: first day since the start of the timeliness window at which the
  cumulative percentage vaccinated (`cdf`) reaches the percentile.

- `age`: age in days at which the percentile is reached
  (`day + age_schedule_low`).

- `within_window`: whether `day` falls within the timeliness window for
  that dose.

- `window_end`: last timely day for that dose.

- `total`: number of vaccinations in the EIR for that `dose` and
  geographic area, excluding those vaccinated before the timeliness
  window and those with a missing date.

It can be passed to `vt_percentile_plot`.
