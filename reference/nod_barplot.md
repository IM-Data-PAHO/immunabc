# (No)minal (D)ropout Bar Plot

(No)minal (D)ropout Bar Plot

## Usage

``` r
nod_barplot(data, order = "alpha", within_ADM1 = NULL)
```

## Arguments

- data:

  Dataframe formatted from the output of the
  [`immunabc::nod_dropout`](https://im-data-paho.github.io/immunabc/reference/nod_dropout.md)
  function.

- order:

  Organizes the bars based on three options: "alpha", "desc" or "asc",
  default is "alpha"

- within_ADM1:

  When analyzing data at the "ADM2" level, this optional character
  vector lets you specify one or several "ADM1" to filter. Default is
  `NULL`, which means no filtering by "ADM1".

## Value

A ggplot object representing the bar plot.
