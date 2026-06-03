# Period for Inevitable Disclosure Doctrine (IDD)

Periods defined by precedent-setting legal cases adopting or rejecting
the Inevitable Disclosure Doctrine (IDD) by state.

## Usage

``` r
get_idd_periods(min_date, max_date)
```

## Arguments

- min_date:

  First date of sample period

- max_date:

  Last date of sample period

## Value

tibble with four columns: state, period_type, start_date, end_date

## Details

Three kinds of period by state:

- Pre-adoption

- Post-adoption

- Post-rejection

## Examples

``` r
idd_periods <- get_idd_periods(min_date = "1994-01-01",
                               max_date = "2010-12-31")
idd_periods
#> # A tibble: 65 × 4
#>    state period_type   start_date end_date  
#>    <chr> <chr>         <date>     <date>    
#>  1 AK    Pre-adoption  1994-01-01 2010-12-31
#>  2 AL    Pre-adoption  1994-01-01 2010-12-31
#>  3 AR    Pre-adoption  1994-01-01 1997-03-18
#>  4 AR    Post-adoption 1997-03-18 2010-12-31
#>  5 AZ    Pre-adoption  1994-01-01 2010-12-31
#>  6 CA    Pre-adoption  1994-01-01 2010-12-31
#>  7 CO    Pre-adoption  1994-01-01 2010-12-31
#>  8 CT    Pre-adoption  1994-01-01 1996-02-28
#>  9 CT    Post-adoption 1996-02-28 2010-12-31
#> 10 DC    Pre-adoption  1994-01-01 2010-12-31
#> # ℹ 55 more rows
```
