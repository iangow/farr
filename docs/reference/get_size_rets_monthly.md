# Create a table of monthly returns for size portfolios

Create a table of monthly returns for size portfolios

## Usage

``` r
get_size_rets_monthly()
```

## Value

A tibble with columns `month` (a Date), `decile` (integers 1–10),
`ew_ret` (equal-weighted returns), and `vw_ret` (value-weighted
returns). Returns are expressed as decimal fractions.

## Examples

``` r
# \donttest{
# Downloads portfolio returns from Ken French's website.
head(get_size_rets_monthly())
#> # A tibble: 6 × 4
#>   month      decile  ew_ret  vw_ret
#>   <date>      <int>   <dbl>   <dbl>
#> 1 1926-07-01      1 -0.0169 -0.0062
#> 2 1926-07-01      2  0.0033  0.0057
#> 3 1926-07-01      3 -0.0024 -0.0013
#> 4 1926-07-01      4  0.009   0.0085
#> 5 1926-07-01      5  0.0148  0.0142
#> 6 1926-07-01      6  0.0194  0.0201
# }
```
