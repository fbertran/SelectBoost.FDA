# Summarize a Functional Association Matrix

Computes structural diagnostics for an association matrix, including
sparsity, within-block mass, local mass, and effective degree.

## Usage

``` r
summarise_association_structure(
  association,
  x = NULL,
  bandwidth = NULL,
  method = NA_character_
)
```

## Arguments

- association:

  Square association matrix.

- x:

  Optional functional input used to recover block and position metadata.
  If omitted, all features are treated as one block.

- bandwidth:

  Optional lag defining local versus nonlocal mass.

- method:

  Optional method label.

## Value

A one-row data frame of association diagnostics.
