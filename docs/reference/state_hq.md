# Data on firm headquarters based on SEC EDGAR filings

Data on firm headquarters based on SEC EDGAR filings. Dates related to
SEC filing dates. Rather than provide dates for all filings, data are
aggregated into groups of filings by state and CIK and dates are
collapsed into windows over which all filings for a given CIK were
associated with a given state. For example, CIK 0000037755 has filings
with a CA headquarters from 1994-06-02 until 1996-03-25, then filings
with an OH headquarters from 1996-05-30 until 1999-04-05, then filings
with a CA headquarters from 1999-06-11 onwards. To ensure continuous
coverage over the sample period, it is assumed that any change in state
occurs the day after the last observed filing for the previous state.

## Usage

``` r
state_hq
```

## Format

A tibble with 53,133 rows and 4 variables:

- cik:

  SEC's Central Index Key (CIK)

- ba_state:

  Two-letter abbreviation of state

- min_date:

  Date of first filing with CIK-state combination in a contiguous series
  of filings

- max_date:

  Date of last filing with CIK-state combination in a contiguous series
  of filings

## Source

<https://sraf.nd.edu/sec-edgar-data/10-x-header-data/>
