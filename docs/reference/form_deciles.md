# Form deciles

Calculate deciles for a variable.

## Usage

``` r
form_deciles(x)
```

## Arguments

- x:

  A vector for which deciles are to be calculated.

## Value

An integer vector the same length as `x`, with decile assignments from 1
(lowest values) to 10 (highest values).

## Examples

``` r
library(farr)
library(dplyr, warn.conflicts = FALSE)

df <-
    tibble(x = rnorm(100)) %>%
    mutate(dec_x = form_deciles(x))
df
#> # A tibble: 100 × 2
#>         x dec_x
#>     <dbl> <int>
#>  1 -1.82      1
#>  2 -0.247     4
#>  3 -0.244     4
#>  4 -0.283     4
#>  5 -0.554     3
#>  6  0.629     8
#>  7  2.07     10
#>  8 -1.63      1
#>  9  0.512     7
#> 10 -1.86      1
#> # ℹ 90 more rows
```
