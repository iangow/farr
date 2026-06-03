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

vector including sensitivity and precision
