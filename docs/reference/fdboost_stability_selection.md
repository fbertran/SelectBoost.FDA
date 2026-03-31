# Stability Selection for FDboost Fits

Thin adapter to the `stabsel.FDboost()` method. This is the native route
when the model itself is already fitted with `FDboost`.

## Usage

``` r
fdboost_stability_selection(model, ...)
```

## Arguments

- model:

  A fitted `FDboost` object.

- ...:

  Additional arguments forwarded to
  [`stabs::stabsel()`](https://rdrr.io/pkg/stabs/man/stabsel.html).

## Value

A `stabsel` object.
