# Fetch Fama-French industry grouping.

Fetch Fama-French industry grouping from Ken French's website.

## Usage

``` r
get_ff_ind(ind, refresh_cache = FALSE)
```

## Arguments

- ind:

  Fama-French industry grouping (e.g., 11, 48)

- refresh_cache:

  If `TRUE`, re-download the underlying zip file even if a cached copy
  is available.

## Value

tbl_df

## Examples

``` r
## Not run:
get_ff_ind(5)
#> # A tibble: 58 × 6
#>    ff_ind ff_ind_short_desc ff_ind_desc                 sic_min sic_max sic_desc
#>     <int> <chr>             <chr>                         <int>   <int> <chr>   
#>  1      1 Cnsmr             Consumer Durables, Nondura…     100     999 ""      
#>  2      1 Cnsmr             Consumer Durables, Nondura…    2000    2399 ""      
#>  3      1 Cnsmr             Consumer Durables, Nondura…    2700    2749 ""      
#>  4      1 Cnsmr             Consumer Durables, Nondura…    2770    2799 ""      
#>  5      1 Cnsmr             Consumer Durables, Nondura…    3100    3199 ""      
#>  6      1 Cnsmr             Consumer Durables, Nondura…    3940    3989 ""      
#>  7      1 Cnsmr             Consumer Durables, Nondura…    2500    2519 ""      
#>  8      1 Cnsmr             Consumer Durables, Nondura…    2590    2599 ""      
#>  9      1 Cnsmr             Consumer Durables, Nondura…    3630    3659 ""      
#> 10      1 Cnsmr             Consumer Durables, Nondura…    3710    3711 ""      
#> # ℹ 48 more rows
## End(Not run)
```
