#' A function returning data on test_scores.
#'
#'  A function returning simulated data on test_scores.
#'
#' @param effect_size Effect of attending camp on subsequent test scores
#' @param n_students Number of students in simulated data set
#' @param n_grades Number of grades in simulated data set
#' @param include_unobservables Include talent in returned data (TRUE or FALSE)
#' @param random_assignment Is assignment to treatment completely random? (TRUE or FALSE)
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
#' @examples
#' set.seed(2021)
#' library(dplyr, warn.conflicts = FALSE)
#' get_test_scores() %>% head()
get_test_scores <- function(effect_size = 15, n_students = 1000L,
                            n_grades = 4L, include_unobservables = FALSE,
                            random_assignment = FALSE) {

  assign_score <- function(x, random_assignment = FALSE) {
    if (!random_assignment) {
      temp <- 1 - (x - min(x))/(max(x) - min(x))
    } else {
      temp <- 1
    }
    stats::runif(n = length(x)) * temp
  }

  treatment_grade <- 7L
  sd_e <- 5
  sd_talent <- 5
  mean_talent <- 15
  mean_score <- 400
  grades <- seq(from = as.integer(treatment_grade - (n_grades)/2), by = 1,
                length.out = n_grades)
  grade_effect_data <- dplyr::tibble(grade = 1:12L,
                                     grade_effect = c(50, 52, 58, 76,
                                                      80, 98, 103, 119,
                                                      123, 131, 138, 150))

  talents <-
    dplyr::tibble(id = 1:n_students) %>%
    dplyr::mutate(talent = stats::rnorm(n = n_students, mean = mean_talent,
                                        sd = sd_talent))

  test_scores_pre <-
    expand.grid(grade = grades,
                id = 1:n_students) %>%
    dplyr::inner_join(talents, by = "id") %>%
    dplyr::inner_join(grade_effect_data, by = "grade") %>%
    dplyr::mutate(score = stats::rnorm(n = length(grades) * n_students,
                                       mean = mean_score, sd = sd_e) +
             .data$talent + .data$grade_effect) %>%
    dplyr::as_tibble()

  treatment <-
    test_scores_pre %>%
    dplyr::filter(.data$grade == treatment_grade - 1L) %>%
    dplyr::mutate(treat_score = assign_score(.data$score,
                                             random_assignment = random_assignment)) %>%
    dplyr::mutate(treat = .data$treat_score > stats::median(.data$treat_score)) %>%
    dplyr::select("id", "treat")

  test_scores <-
    test_scores_pre %>%
    dplyr::inner_join(treatment, by = "id") %>%
    dplyr::mutate(post = .data$grade >= treatment_grade) %>%
    dplyr::mutate(score =
      dplyr::case_when(.data$treat & .data$post ~ .data$score + effect_size,
                       TRUE ~ .data$score)) %>%
    dplyr::select("id", "grade", "post", "treat", "score",
                  "talent", "grade_effect") %>%
    dplyr::as_tibble()

    if (include_unobservables) {
      return(test_scores)
    } else {
      return(dplyr::select(test_scores, -c("talent", -"grade_effect")))
    }


}
