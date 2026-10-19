# Confusion statistics.

A function returning sensitivity and precision.

## Usage

``` r
confusion_stats(scores, response, predicted = NULL, k = NULL)
```

## Arguments

- scores:

  Probability that response is true or 1.

- response:

  Responses coded as logical or 0-or-1.

- predicted:

  Predicted value coded as 0-or-1.

- k:

  Percentage to classify as TRUE or 1.

## Value

A named numeric vector containing sensitivity (the fraction of positive
responses detected) and precision (the fraction of predictions
classified as positive that have a positive response).

## Examples

``` r
scores <- c(0.1, 0.4, 0.35, 0.8)
response <- c(0, 0, 1, 1)
confusion_stats(scores, response)
#> sensitivity   precision
#>         0.5         1.0
```
