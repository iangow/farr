# Winsorize a vector

Winsorize a vector at `prob` and `1 - prob`.

## Usage

``` r
winsorize(x, prob = 0.01, p_low = prob, p_high = 1 - prob)
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
winsorized <- winsorize(1:100, prob = 0.05)
min(winsorized, na.rm = TRUE)
#> [1] 5.5
max(winsorized, na.rm = TRUE)
#> [1] 95.5
```
