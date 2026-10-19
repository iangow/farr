# Area under curve

A function returning AUC.

## Usage

``` r
auc(scores, response)
```

## Source

<https://blog.mbq.me/augh-roc/>

<https://stackoverflow.com/questions/4903092/calculate-auc-in-r>

## Arguments

- scores:

  Probability that response is true or 1.

- response:

  Responses coded as logical or 0-or-1.

## Value

A named numeric vector containing the area under the ROC curve.

## Examples

``` r
scores <- c(0.1, 0.4, 0.35, 0.8)
response <- c(0, 0, 1, 1)
auc(scores, response)
#>  auc
#> 0.75
```
