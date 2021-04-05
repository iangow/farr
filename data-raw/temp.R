data <-
    apple_events %>%
    mutate(permno = 14593L)

win_start <- -1
win_end <- 1
end_event_date <- "end_event_date"
conn <- pg

Sys.setenv(PGHOST="localhost", PGUSER="iangow", PGPORT=5432L, PGDATABASE="crsp")
Sys.setenv(PGHOST="iangow.me", PGUSER="iangow", PGPORT=5434L, PGDATABASE="crsp")
pg <- DBI::dbConnect(RPostgres::Postgres(), bigint = "integer", sslmode='allow')
rs <- dbExecute(pg, "SET work_mem TO '3GB'")

results_alt <-
    apple_events %>%
    mutate(permno = 14593L) %>%
    get_event_rets(pg,
               win_start = -1, win_end = +1,
               end_event_date = "end_event_date")
