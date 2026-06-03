# Generate simulated data as described in Gow, Ormazabal and Taylor (2010).

Function to generate simulated panel data as described in Gow, Ormazabal
and Taylor (2010).

## Usage

``` r
get_got_data(N = 400, T = 20, Xvol, Evol, rho_X, rho_E)
```

## Source

<https://www.jstor.org/stable/20744139>

## Arguments

- N:

  Number of firms

- T:

  Number of years

- Xvol:

  Cross-sectional correlation of *X*

- Evol:

  Cross-sectional correlation of errors

- rho_X:

  Autocorrelation coefficient for firm-effect portion of *X*

- rho_E:

  Autocorrelation coefficient for firm-effect portion of epsilon

## Value

tibble

## Examples

``` r
set.seed(2021)
test <- get_got_data(N = 500, T = 10, Xvol = 0.75,
                     Evol = 0.75, rho_X = 0.5, rho_E = 0.5)
```
