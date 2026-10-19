# Create a table with cut-offs for size portfolios

Create a table with cut-offs for size portfolios

## Usage

``` r
get_me_breakpoints(keep_max = FALSE)
```

## Arguments

- keep_max:

  Set to `TRUE` to keep upper-bound of highest decile. Default is
  `FALSE`, which will replace upper bound with `Inf`.

## Value

A tibble with columns `month` (a Date), `decile` (integers 1–10),
`me_min` and `me_max` (lower and upper market-equity cut-offs in
millions of dollars). Unless `keep_max` is `TRUE`, the highest upper
bound is `Inf`.

## Examples

``` r
# \donttest{
# Downloads market-equity breakpoints from Ken French's website.
head(get_me_breakpoints())
#> # A tibble: 6 × 4
#>   month      decile me_min me_max
#>   <date>      <int>  <dbl>  <dbl>
#> 1 1925-12-01      1   0      2.38
#> 2 1925-12-01      2   2.38   4.96
#> 3 1925-12-01      3   4.96   7.4
#> 4 1925-12-01      4   7.4   10.8
#> 5 1925-12-01      5  10.8   15.6
#> 6 1925-12-01      6  15.6   22.9
# }
```
