# A function returning data on test_scores

A function returning simulated data on test_scores.

## Usage

``` r
get_test_scores(
  effect_size = 15,
  n_students = 1000L,
  n_grades = 4L,
  include_unobservables = FALSE,
  random_assignment = FALSE
)
```

## Arguments

- effect_size:

  Effect of attending camp on subsequent test scores

- n_students:

  Number of students in simulated data set

- n_grades:

  Number of grades in simulated data set

- include_unobservables:

  Include talent in returned data (TRUE or FALSE)

- random_assignment:

  Is assignment to treatment completely random? (TRUE or FALSE)

## Value

tbl_df

## Examples

``` r
set.seed(2021)
library(dplyr, warn.conflicts = FALSE)
get_test_scores() %>% head()
#> # A tibble: 6 × 6
#>      id grade post  treat score grade_effect
#>   <int> <dbl> <lgl> <lgl> <dbl>        <dbl>
#> 1     1     5 FALSE TRUE   498.           80
#> 2     1     6 FALSE TRUE   513.           98
#> 3     1     7 TRUE  TRUE   521.          103
#> 4     1     8 TRUE  TRUE   552.          119
#> 5     2     5 FALSE TRUE   480.           80
#> 6     2     6 FALSE TRUE   515.           98
```
