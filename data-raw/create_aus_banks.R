library(dplyr, warn.conflicts = FALSE)
library(DBI)
library(forcats)

pg <- dbConnect(RPostgres::Postgres())
g_company <- tbl(pg, sql("SELECT * FROM comp.g_company"))
g_funda <- tbl(pg, sql("SELECT * FROM comp.g_funda"))
g_secd <- tbl(pg, sql("SELECT * FROM comp.g_secd"))
g_security <- tbl(pg, sql("SELECT * FROM comp.g_security"))

aus_banks_pg <-
    g_company %>%
    filter(fic == "AUS", gind == "401010") %>%
    select(gvkey, conm, conml)

aus_bank_stocks <-
    aus_banks_pg %>%
    inner_join(g_security, by = "gvkey") %>%
    filter(exchg == 106, !is.na(ibtic), iid == "01W") %>%
    select(gvkey, iid)

aus_bank_funds <-
    g_funda %>%
    semi_join(aus_banks_pg, by = c("gvkey", "conm")) %>%
    filter(indfmt == "FS",
           datafmt == "HIST_STD",
           consol == "C",
           popsrc == "I",
           !is.na(at)) %>%
    select(gvkey, datadate, at, ceq, ib, xi, do) %>%
    collect()

month_rets <-
    g_secd %>%
    filter(monthend == 1, !is.na(prccd)) %>%
    filter(datadate != "2022-11-07") %>%
    semi_join(aus_bank_stocks, by = c("gvkey", "iid")) %>%
    mutate(gret = prccd / ajexdi * trfd,
           mkt_cap = prccd * cshoc/1e6) %>%
    group_by(gvkey, iid) %>%
    dbplyr::window_order(datadate) %>%
    mutate(ret = if_else(lag(gret) > 0, gret/lag(gret) - 1, NA)) %>%
    select(gvkey, iid, datadate, ret, mkt_cap) %>%
    ungroup()

aus_bank_last_dates <-
    month_rets %>%
    group_by(gvkey, iid) %>%
    summarize(last_date = max(datadate, na.rm = TRUE), .groups = "drop") %>%
    filter(last_date >= "2000-01-01")

aus_bank_rets_pg <-
    aus_bank_stocks %>%
    semi_join(aus_bank_last_dates, by = c("gvkey", "iid")) %>%
    inner_join(month_rets, by = c("gvkey", "iid")) %>%
    select(gvkey, iid, datadate, ret, mkt_cap)

aus_bank_tickers <-
    aus_bank_stocks %>%
    semi_join(aus_bank_last_dates, by = c("gvkey", "iid")) %>%
    semi_join(month_rets, by = c("gvkey", "iid")) %>%
    inner_join(g_security, by = c("gvkey", "iid")) %>%
    mutate(ticker = regexp_replace(ibtic, "^@", "")) %>%
    select(gvkey, iid, ticker) %>%
    distinct() %>%
    mutate(ticker = case_when(ticker == "CU7" ~ "CBA",
                              ticker == "ANB" ~ "ANZ",
                              ticker == "BE6" ~ "BEN",
                              ticker == "BUI" ~ "ADB",
                              ticker == "QBQ" ~ "BOQ",
                              ticker == "BE6" ~ "BEN",
                              ticker == "GXB" ~ "SGB",
                              ticker == "B2W" ~ "BWA",
                              ticker == "AATX" ~ "BBC",
                              TRUE ~ ticker)) %>%
    semi_join(aus_bank_rets_pg, by = c("gvkey", "iid"))

aus_bank_rets <-
    aus_bank_rets_pg %>%
    select(-iid) %>%
    arrange(gvkey, datadate) %>%
    collect()

aus_banks <-
    aus_banks_pg %>%
    inner_join(aus_bank_tickers, by = "gvkey") %>%
    select(gvkey, ticker, conml) %>%
    rename(co_name = conml) %>%
    collect()

usethis::use_data(aus_banks, version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(aus_bank_rets, version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(aus_bank_funds, version = 3, compress="xz", overwrite=TRUE)

