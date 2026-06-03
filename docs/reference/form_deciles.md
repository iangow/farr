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

vector

## Examples

``` r
library(farr)
library(dplyr, warn.conflicts = FALSE)

df <-
    tibble(x = rnorm(100)) %>%
    mutate(dec_x = form_deciles(x))
df
#> # A tibble: 100 × 2
#>           x dec_x
#>       <dbl> <int>
#>  1 -1.40        2
#>  2  0.255       6
#>  3 -2.44        1
#>  4 -0.00557     5
#>  5  0.622       8
#>  6  1.15        9
#>  7 -1.82        1
#>  8 -0.247       4
#>  9 -0.244       4
#> 10 -0.283       3
#> # ℹ 90 more rows
```
