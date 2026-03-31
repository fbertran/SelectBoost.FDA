# Functional Predictor on a Common Grid

Constructor for one discretized functional predictor sampled on a common
grid.

## Usage

``` r
fda_grid(values, argvals = NULL, name = NULL, unit = NULL)
```

## Arguments

- values:

  Numeric matrix with one row per observation.

- argvals:

  Optional vector of grid values. Defaults to `seq_len(ncol(values))`.

- name:

  Optional predictor name.

- unit:

  Optional unit for the grid axis.

## Value

An object of class `fda_grid`.
