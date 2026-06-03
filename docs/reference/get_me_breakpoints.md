# Create a table of with cut-offs for size portfolios

Create a table of with cut-offs for size portfolios

## Usage

``` r
get_me_breakpoints(keep_max = FALSE)
```

## Arguments

- keep_max:

  Set to `TRUE` to keep upper-bound of highest decile. Default is
  `FALSE`, which will replace upper bound with `Inf`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr, warn.conflicts = FALSE)
get_me_breakpoints() %>% filter(month == '2022-04-01')
} # }
```
