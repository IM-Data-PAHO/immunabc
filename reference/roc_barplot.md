# (R)esidence (Oc)currence Bar Plot

This function creates a bar plot showing vaccination coverage by place
of residence and place of vaccination occurrence.

## Usage

``` r
roc_barplot(data, year, vaccine, within_ADM1 = NULL)
```

## Arguments

- data:

  The output from the
  [`immunabc::roc_coverage()`](https://im-data-paho.github.io/immunabc/reference/roc_coverage.md)
  function.

- year:

  A numeric value specifying the year of the data to be plotted. Only
  one year.

- vaccine:

  A string specifying the vaccine of interest. Only one vaccine.

- within_ADM1:

  When analyzing data at the "ADM2" level, this optional character
  vector lets you specify one or several "ADM1" to filter. Default is
  `NULL`, which means no filtering by "ADM1".

## Value

A ggplot object representing the bar plot.
