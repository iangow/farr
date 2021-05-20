library(dplyr, warn.conflicts = FALSE)

set.seed(2021)

get_test_scores <- function() {
    assign_score <- function(x) {
        temp <- 1 - (x - min(x))/(max(x) - min(x))
        runif(n = length(x)) * temp
    }

    effect_size <- 15
    n_students <- 1000L
    grade_trend <- 10
    sd_e <- 5
    sd_talent <- 5
    mean_talent <- 15
    mean_score <- 400

    talents <-
        tibble(id = 1:n_students) %>%
        mutate(talent = rnorm(n = nrow(.), mean = mean_talent, sd = sd_talent))

    test_scores_pre <-
        expand.grid(grade = 8:11L, id = 1:n_students) %>%
        inner_join(talents, by = "id") %>%
        mutate(score = rnorm(n = nrow(.), mean = mean_score, sd = sd_e) + talent +
                   grade * grade_trend)

    treatment <-
        test_scores_pre %>%
        filter(grade == 9) %>%
        mutate(treat_score = assign_score(score)) %>%
        mutate(treat = treat_score > median(treat_score)) %>%
        select(id, treat)

    test_scores <-
        test_scores_pre %>%
        inner_join(treatment, by = "id") %>%
        mutate(post = grade >= 10,
               score = case_when(treat & post ~ score + effect_size,
                                 TRUE ~ score)) %>%
        select(id, grade, post, treat, score) %>%
        as_tibble()
}

test_scores <- get_test_scores()

usethis::use_data(test_scores, version = 3, compress="xz", overwrite=TRUE)
