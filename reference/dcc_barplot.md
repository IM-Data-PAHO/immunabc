# (D)ate (C)onsistency (C)omparison Barplot

Generates a bar plot of date consistencies, grouped by geographic area
and colored by consistency result.

## Usage

``` r
dcc_barplot(
  data,
  date_1_name = "date 1",
  date_2_name = "date 2",
  within_ADM1 = NULL,
  plot_missing = TRUE
)
```

## Arguments

- data:

  The output from the
  [`immunabc::dcc_rate`](https://im-data-paho.github.io/immunabc/reference/dcc_rate.md)
  function.

- date_1_name:

  Character. Label for the first date variable, used in the plot
  subtitle.

- date_2_name:

  Character. Label for the second date variable, used in the plot
  subtitle.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- plot_missing:

  Boolean (default TRUE). Plots DATE_MISSING records as its own
  category. Defaults to TRUE so all bars add to 100

## Value

A ggplot object representing the bar plot.
