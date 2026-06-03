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

vector including sensitivity and precision
