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

A tibble with industry identifiers (`ff_ind`), short and long
descriptions (`ff_ind_short_desc`, `ff_ind_desc`), SIC interval
endpoints (`sic_min`, `sic_max`), and SIC interval descriptions
(`sic_desc`).

## Examples

``` r
# \donttest{
# Downloads an industry classification from Ken French's website.
local({
  cache_dir <- tempfile("farr-example-cache-")
  old_options <- options(farr.cache_dir = cache_dir)
  on.exit({
    options(old_options)
    unlink(cache_dir, recursive = TRUE)
  }, add = TRUE)
  head(get_ff_ind(5))
})
#> # A tibble: 6 × 6
#>   ff_ind ff_ind_short_desc ff_ind_desc                  sic_min sic_max sic_desc
#>    <int> <chr>             <chr>                          <int>   <int> <chr>
#> 1      1 Cnsmr             Consumer Durables, Nondurab…     100     999 ""
#> 2      1 Cnsmr             Consumer Durables, Nondurab…    2000    2399 ""
#> 3      1 Cnsmr             Consumer Durables, Nondurab…    2700    2749 ""
#> 4      1 Cnsmr             Consumer Durables, Nondurab…    2770    2799 ""
#> 5      1 Cnsmr             Consumer Durables, Nondurab…    3100    3199 ""
#> 6      1 Cnsmr             Consumer Durables, Nondurab…    3940    3989 ""
# }
```
