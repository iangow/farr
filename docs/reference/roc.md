# A function returning data for a ROC plot.

A function returning data for a ROC plot.

## Usage

``` r
roc(scores, response)
```

## Arguments

- scores:

  Probability that response is true or 1.

- response:

  Responses coded as logical or 0-or-1.

## Value

A tibble with columns `fpr` (false positive rate) and `tpr` (true
positive rate), with one row per distinct point on the ROC curve.

## Examples

``` r
scores <- c(0.1, 0.4, 0.35, 0.8)
response <- c(0, 0, 1, 1)
roc(scores, response)
#> # A tibble: 5 × 2
#>     fpr   tpr
#>   <dbl> <dbl>
#> 1   1     1
#> 2   0.5   1
#> 3   0.5   0.5
#> 4   0     0.5
#> 5   0     0
```
