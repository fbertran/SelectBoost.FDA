# Basis-Expanded Functional Predictor

Constructor for a functional predictor represented by basis coefficients
or FPCA scores.

## Usage

``` r
fda_basis(
  coefficients,
  basis_type = c("generic", "spline", "wavelet", "fpca"),
  argvals = NULL,
  component_names = NULL,
  name = NULL,
  unit = NULL
)
```

## Arguments

- coefficients:

  Numeric matrix with one row per observation.

- basis_type:

  Label describing the representation.

- argvals:

  Optional labels or positions for basis functions/components.

- component_names:

  Optional names for coefficient columns.

- name:

  Optional predictor name.

- unit:

  Optional unit for the basis domain.

## Value

An object of class `fda_basis`.
