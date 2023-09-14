library(dplyr, warn.conflicts = FALSE)

set.seed(2021)

test_scores <- farr::get_test_scores(include_unobservables = FALSE)

usethis::use_data(test_scores, version = 3, compress="xz", overwrite=TRUE)
