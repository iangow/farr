# Data on public float

Data on public float of listed companies from Iliev (2010).

## Usage

``` r
iliev_2010
```

## Format

A tibble with 7,214 rows and 9 variables:

- gvkey:

  Compustat firm identifier (GVKEY)

- fyear:

  Fiscal year

- fdate:

  Date of end of fiscal year

- pfdate:

  Date for public float value

- pfyear:

  Year for public float value

- publicfloat:

  Public float in \$ million

- mr:

  Indicator for filing of a management report

- af:

  Indicator for accelerator filer

- cik:

  SEC firm identifier (CIK)

## Source

[doi:10.1111/j.1540-6261.2010.01564.x](https://doi.org/10.1111/j.1540-6261.2010.01564.x)

## Details

Five public-float dates have been corrected against the companies' Form
10-K cover pages: Spectrum Control (CIK 92769), fiscal year 2004, and
Whitehall Jewellers (CIK 868984), fiscal years 2003–2006. These
corrections replace four fractional values of `pfyear` and correct four
months, with corresponding updates to `pfdate`. The original source CSV
is preserved. The original values, corrected dates, and filing links are
recorded in `data-raw/iliev_2010_date_corrections.csv` in the source
repository; see also [the investigation and filing
evidence](https://github.com/iangow/farr/issues/28). Other source
anomalies, including invalid dates represented by missing values, remain
in the data.
