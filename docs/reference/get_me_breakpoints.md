# Create a table of with cut-offs for size portfolios

Create a table of with cut-offs for size portfolios

## Usage

``` r
get_me_breakpoints(keep_max = FALSE)
```

## Arguments

- keep_max:

  Set to `TRUE` to keep upper-bound of highest decile. Default is
  `FALSE`, which will replace upper bound with `Inf`.

## Examples

``` r
library(dplyr, warn.conflicts = FALSE)
get_me_breakpoints() %>% filter(month == '2022-04-01')
#> # A tibble: 10 × 4
#>    month      decile me_min me_max
#>    <date>      <int>  <dbl>  <dbl>
#>  1 2022-04-01      1     0    384.
#>  2 2022-04-01      2   384.   838.
#>  3 2022-04-01      3   838.  1542.
#>  4 2022-04-01      4  1542.  2473 
#>  5 2022-04-01      5  2473   3745.
#>  6 2022-04-01      6  3745.  5522.
#>  7 2022-04-01      7  5522.  8852.
#>  8 2022-04-01      8  8852. 17800.
#>  9 2022-04-01      9 17800. 41618.
#> 10 2022-04-01     10 41618.   Inf 
```
