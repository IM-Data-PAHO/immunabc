# Dose (S)equence (C)omparison Barplot

Generates a stacked bar plot of dose sequences, grouped by geographic
area, from the output of `sc_rate`: consistent and inconsistent
sequences (`aggregated = TRUE`) or consistent sequences and every
inconsistent combination of doses received (`aggregated = FALSE`).
Sequences that cannot be fully evaluated because a date is missing are
shown as `DATE_MISSING`.

## Usage

``` r
sc_barplot(
  data,
  sequence_name = "dose sequence",
  within_ADM1 = NULL,
  plot_missing = TRUE
)
```

## Arguments

- data:

  The output from the
  [`immunabc::sc_rate`](https://im-data-paho.github.io/immunabc/reference/sc_rate.md)
  function.

- sequence_name:

  Character. Label for the dose sequence, used in the plot subtitle
  (e.g. `"DTP1 - DTP3"`). Default is `"dose sequence"`.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- plot_missing:

  Boolean (default TRUE). Plots DATE_MISSING sequences as its own
  category. Defaults to TRUE so all bars add to 100.

## Value

A ggplot object representing the bar plot.
