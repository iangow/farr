# Compound simple returns without evaluating LN(0) for a complete loss.
# NULLIF protects aggregate inputs even when SQL evaluates them before CASE.
# MIN below -1 bypasses the zero branch and retains the logarithm domain error.
gross_return_sql <- function(column) {
    dbplyr::sql(paste0(
        "CASE WHEN COUNT(", column, ") = 0 THEN NULL ",
        "WHEN MIN(", column, ") = -1 THEN 0 ",
        "ELSE EXP(SUM(LN(NULLIF(1 + ", column, ", 0)))) END"
    ))
}
