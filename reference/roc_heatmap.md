# (R)esidence (Oc)currence Heatmap

This function generates a heatmap displaying the proportion of doses
administered by place of occurrence, for each place of residence.

## Usage

``` r
roc_heatmap(data, digits = 0)
```

## Arguments

- data:

  The output from the
  [`immunabc::roc_distribution`](https://im-data-paho.github.io/immunabc/reference/roc_distribution.md)
  function.

- digits:

  The number of digits to show in the labels. Default is 0.

## Value

A ggplot object representing the heatmap.
