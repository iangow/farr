library(dplyr, warn.conflicts = FALSE)

set.seed(2021)

test_scores <- farr::get_test_scores(include_unobservables = FALSE)
camp_attendance <-
    test_scores |>
    select(id, treat) |>
    distinct() |>
    rename(camp = treat)

test_scores <-
    test_scores |>
    select(id, grade, score)

usethis::use_data(test_scores, version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(camp_attendance, version = 3, compress="xz", overwrite=TRUE)
