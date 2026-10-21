# Compound simple returns without evaluating LN(0) for a complete loss.
# NULLIF protects aggregate inputs even when SQL evaluates them before CASE.
# PostgreSQL raises for negative logarithm inputs. DuckDB needs an explicit
# check because LN() can return NaN with ieee_floating_point_ops enabled.
gross_return_sql <- function(column, conn) {
    log_return <- paste0("LN(NULLIF(1 + ", column, ", 0))")
    if (inherits(conn, "duckdb_connection")) {
        log_return <- paste0(
            "CASE WHEN ", column, " < -1 THEN ",
            "ERROR('Returns below -1 imply a negative gross return.') ",
            "ELSE ", log_return, " END"
        )
    }

    dbplyr::sql(paste0(
        "CASE WHEN COUNT(", column, ") = 0 THEN NULL ",
        "WHEN MIN(", column, ") = -1 THEN 0 ",
        "ELSE EXP(SUM(", log_return, ")) END"
    ))
}
