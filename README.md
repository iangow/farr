
<!-- README.md is generated from README.Rmd. Please edit that file -->

# farr

<!-- badges: start -->
<!-- badges: end -->

The goal of farr is to …

## Installation

You can install the released version of farr from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("farr")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("iangow/farr")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(farr)
library(dplyr, warn.conflicts = FALSE)
library(DBI)

pg <- dbConnect(RPostgres::Postgres(), bigint = "integer", sslmode='require')

url <- "https://github.com/tidyverse/dbplyr/files/6239289/temp.RDS.zip"
t <- tempfile(fileext = ".zip")
download.file(url, t)
temp <- as.tbl(readRDS(unzip(t)))
#> Warning: `as.tbl()` was deprecated in dplyr 1.0.0.
#> Please use `tibble::as_tibble()` instead.
unlink("temp.RDS")

temp2 <- df_to_pg(temp, pg)

temp
#> # A tibble: 83,441 x 3
#>    gvkey  datadate   rdq       
#>    <chr>  <date>     <date>    
#>  1 001004 2010-05-31 2010-07-13
#>  2 001004 2011-05-31 2011-07-06
#>  3 001004 2012-05-31 2012-07-17
#>  4 001004 2013-05-31 2013-07-25
#>  5 001004 2014-05-31 2014-07-15
#>  6 001004 2017-05-31 2017-07-11
#>  7 001004 2015-05-31 2015-07-13
#>  8 001004 2016-05-31 2016-07-12
#>  9 001004 2018-05-31 2018-07-10
#> 10 001004 2019-05-31 2019-07-10
#> # … with 83,431 more rows

temp2
#> # Source:   SQL [?? x 3]
#> # Database: postgres [iangow@/tmp:5432/crsp]
#>    gvkey  datadate   rdq       
#>    <chr>  <date>     <date>    
#>  1 001004 2010-05-31 2010-07-13
#>  2 001004 2011-05-31 2011-07-06
#>  3 001004 2012-05-31 2012-07-17
#>  4 001004 2013-05-31 2013-07-25
#>  5 001004 2014-05-31 2014-07-15
#>  6 001004 2017-05-31 2017-07-11
#>  7 001004 2015-05-31 2015-07-13
#>  8 001004 2016-05-31 2016-07-12
#>  9 001004 2018-05-31 2018-07-10
#> 10 001004 2019-05-31 2019-07-10
#> # … with more rows
```
