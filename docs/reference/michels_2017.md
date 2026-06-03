# Data on firms suffering natural disasters

Data on firms suffering natural disasters based on the sample in Michels
(2017).

## Usage

``` r
michels_2017
```

## Format

A tibble with 423 rows and 12 variables:

- cusip:

  CUSIP supplied by Michels (2017)

- eventdate:

  Date of relevant natural disaster supplied by Michels (2017)

- cik:

  Matched CIK (SEC firm identifier)

- permno:

  Matched PERMNO (CRSP security identifier)

- gvkey:

  Matched GVKEY (Compustat firm identifier)

- date_filed:

  Date of next filing of type 10-Q, 10-K, 10QSB, 10-K405 after event

- form_types:

  List of relevant form types filed on date_filed

- next_period_end:

  Next fiscal period-end after event date

- next_fqtr:

  Fiscal quarter of next period-end after event date

- prev_period_end:

  Last fiscal period-end before event date

- prev_fqtr:

  Fiscal quarter of last period-end before event date

- recognize:

  Indicator for event being recognized (next_period_end before
  date_filed)

## Source

[doi:10.1111/1475-679X.12128](https://doi.org/10.1111/1475-679X.12128)
