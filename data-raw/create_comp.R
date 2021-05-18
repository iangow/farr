library(dplyr, warn.conflicts = FALSE)
library(dbplyr)
library(DBI)

pg <- dbConnect(RPostgres::Postgres(), bigint = "integer")

company <- tbl(pg, sql("SELECT * FROM comp.company"))
funda <- tbl(pg, sql("SELECT * FROM comp.funda"))

comp_pre <-
    funda %>%
    filter(indfmt == "INDL", datafmt == "STD",
           consol == "C", popsrc == "D") %>%
    filter(!between(sich, 6000, 6999) | is.na(sich)) %>%
    filter(between(fyear, 1995, 2015)) %>%
    group_by(gvkey) %>%
    window_order(fyear) %>%
    mutate(big_n = as.integer(au) %in% 1:8L,
           lag_at = lag(at),
           inv_at = if_else(lag_at > 0, 1/lag_at, NA_real_),
           ta = if_else(lag_at > 0, (ib - oancf)/lag_at, NA_real_),
           roa = if_else(lag_at > 0, ib/lag_at, NA_real_),
           cfo = if_else(lag_at > 0, oancf/lag_at, NA_real_),
           mkt_cap = prcc_f * csho,
           lag_mkt_cap = lag(mkt_cap),
           size = if_else(lag_mkt_cap > 0, log(lag_mkt_cap), NA_real_),
           debt = coalesce(dltt, 0) + coalesce(dlc, 0),
           lev = if_else(lag_at > 0, debt/lag_at, NA_real_),
           mtb = if_else(lag(ceq) > 0, lag_mkt_cap/lag(ceq), NA_real_),
           assets = lag_at,
           d_sale = if_else(lag_at > 0, (revt - lag(revt))/lag_at, NA_real_),
           d_ar =  if_else(lag_at > 0, (rect - lag(rect))/lag_at, NA_real_),
           ppe = if_else(lag_at > 0, ppent/lag_at, NA_real_)) %>%
    ungroup() %>%
    select(gvkey, datadate, fyear, big_n, ta, big_n, roa, cfo, size, lev,
           mtb, inv_at, d_sale, d_ar, ppe) %>%
    collect()

# Get list of all firm IDs
all_firms <-
    comp %>%
    select(gvkey) %>%
    distinct()

# Select 2,000 firms at random
set.seed(2021)
sample_firms <- tibble(gvkey = sample(firms$gvkey, size = 2000, replace = FALSE))

comp <-
    comp_pre %>%
    semi_join(sample_firms, by = "gvkey")

usethis::use_data(comp, version = 3, compress="xz", overwrite=TRUE)
