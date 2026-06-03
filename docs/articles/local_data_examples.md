# Examples with Local Data

This article is a placeholder for examples that should be rendered
locally before publishing the pkgdown site. That workflow is useful when
an example depends on licensed data, local database access, or files
that should not be stored in the public GitHub repository.

The package’s included data can be used in public examples without
additional setup:

``` r

library(farr)
#> 
#> Attaching package: 'farr'
#> The following object is masked from 'package:base':
#> 
#>     truncate
library(dplyr, warn.conflicts = FALSE)

comp |>
  select(gvkey, fyear, big_n, ta, roa) |>
  slice_head(n = 5)
#> # A tibble: 5 × 5
#>   gvkey  fyear big_n     ta     roa
#>   <chr>  <int> <lgl>  <dbl>   <dbl>
#> 1 001038  1995 TRUE  NA     NA     
#> 2 001038  1996 TRUE  -0.238  0.0393
#> 3 001038  1997 TRUE  -0.161 -0.0341
#> 4 001038  1998 TRUE  -0.105 -0.0201
#> 5 001038  1999 TRUE  -0.142 -0.0506
```

For examples that depend on private inputs, keep the source code in this
article and render the site locally with:

``` r

pkgdown::build_site()
```

The rendered HTML under `docs/` can then be published without committing
the underlying private data.
