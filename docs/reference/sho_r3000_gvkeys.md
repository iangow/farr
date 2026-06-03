# Russell 3000 sample used by SEC with GVKEYs

A data set containing the tickers, PERMNOs, GVKEYs, and treatment
assignments for Russell 3000 sample used by SEC.

## Usage

``` r
sho_r3000_gvkeys
```

## Format

A tibble with 2,951 rows × 3 variables.

- ticker:

  Ticker

- permno:

  PERMNO (CRSP security identifier)

- gvkey:

  GVKEY (Compustat firm identifier)

- pilot:

  Indicator for stock being part of Reg SHO pilot program

## Source

<https://iangow.github.io/far_book/natural-revisited.html#the-sho-pilot-sample>
