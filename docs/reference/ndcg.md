# Calculate metric: NDCG at k

A function returning NDCG-at-k metric.

## Usage

``` r
ndcg(scores, response, k = 0.01)
```

## Arguments

- scores:

  Probability that response is true or 1.

- response:

  Responses coded as logical or 0-1.

- k:

  Percentage to classify as TRUE or 1.

## Value

A named numeric vector containing normalized discounted cumulative gain
among the highest-scoring fraction `k` of observations.

## Examples

``` r
scores <- c(0.1, 0.4, 0.35, 0.8)
response <- c(0, 0, 1, 1)
ndcg(scores, response, k = 0.5)
#>  ndcg_0.5
#> 0.6131472
```
