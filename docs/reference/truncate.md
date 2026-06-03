# Truncate a vector.

Truncate a vector at `prob` and `1 - prob`. Extreme values are turned
into `NA` values.

## Usage

``` r
truncate(x, prob = 0.01, p_low = prob, p_high = 1 - prob)
```

## Arguments

- x:

  A vector to be winsorized

- prob:

  Level (two-sided) for winsorization (e.g., 0.01 gives 1% and 99%)

- p_low:

  Optional lower level for winsorization (e.g., 0.01 gives 1%)

- p_high:

  Optional upper level for winsorization (e.g., 0.99 gives 99%)

## Value

vector

## Examples

``` r
trunced <- truncate(1:100, prob = 0.05)
min(trunced, na.rm = TRUE)
#> [1] 6
max(trunced, na.rm = TRUE)
#> [1] 95
```
