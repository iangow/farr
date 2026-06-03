# Customer names that represent non-disclosures

Data to be combined with data in `compsegd.seg_customer` to create an
indicator for non-disclosure of customer names.

## Usage

``` r
undisclosed_names
```

## Format

A tibble with 460 rows and 2 variables:

- cnms:

  Matches field in `compsegd.seg_customer` (WRDS)

- disclosure:

  Indicator that name is not disclosed
