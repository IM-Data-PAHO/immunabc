# (D)uplicate (D)oses Heatmap

Generates a heatmap of duplicate (or repeated) records from the output
of `dd_rate`. The heatmap naturally combines two variables, so it can be
used to visualize the data for each geographic area and one of the other
disaggregation variables: vaccines or birth cohorts. `data` must
therefore come from `dd_rate` with a `geo_level` of "ADM1" or "ADM2" and
a value for `disaggregate_by`.

## Usage

``` r
dd_heatmap(
  data,
  value = "rate",
  duplication = "duplicate",
  within_ADM1 = NULL,
  min_total = NULL,
  digits = 1,
  show_numbers = TRUE
)
```

## Arguments

- data:

  The output from the
  [`immunabc::dd_rate`](https://im-data-paho.github.io/immunabc/reference/dd_rate.md)
  function.

- value:

  Character. What to show in the cells: "rate" (default), the percentage
  of records in the `duplication` category, which shows where the
  problem is proportionally worst; or "n", the total number, which shows
  where most records need correcting.

- duplication:

  Character. Which records to show: "duplicate" (default), the extra
  records with the same person, dose, vaccination date and place of
  occurrence as an earlier record; or "repeated", the extra records with
  the same person and dose but a different date or place.

- within_ADM1:

  Character (optional). When analyzing data at the "ADM2" level, this
  optional character vector lets you specify one or several "ADM1" to
  filter. Default is `NULL`, which means no filtering by "ADM1".

- min_total:

  Numeric (optional). Minimum number of records for a cell to be filled,
  since rates based on few records can be misleading. Other cells are
  grey and blank. Default is `NULL`, which fills all cells.

- digits:

  The number of digits to show in the cells when `value` is "rate".
  Default is 1.

- show_numbers:

  Logical. Whether to show the number in each cell (TRUE, default) or a
  color legend instead (FALSE). Use when there are too many cells to
  read their numbers (e.g. at the "ADM2" level).

## Value

A ggplot object representing the heatmap.
