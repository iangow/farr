#' Version of `system.time()` that works with assignment
#'
#' Print CPU (and other) times that `expr` used, return value of `expr`.
#'
#' @param expr Valid R expression to be timed, evaluated and returned
#'
#' @return Result of evaluating `expr`
#' @export
system_time <- function(expr) {
    print(system.time(expr))
    expr
}
