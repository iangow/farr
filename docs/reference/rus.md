# Random under-sampling function

Function to create temporary training dataset using distribution implied
by w.

## Usage

``` r
rus(y_train, ir = 1)
```

## Arguments

- y_train:

  df on the target variable.

- ir:

  Imbalance ratio. Specifies how many times the under-sampled majority
  instances are over minority instances.

## Value

vector

## Details

Following MATLAB, function samples observations of the minority class
with replacement and observations of the majority class without
replacement.
