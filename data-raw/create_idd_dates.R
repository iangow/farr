idd_dates <-
    dplyr::tribble(
       c
        "CT", "1996-02-28", "Adopt",
        "DE", "1964-05-05", "Adopt",
        "FL", "1960-07-11", "Adopt",
        "FL", "2001-05-21", "Reject",
        "GA", "1998-06-29", "Adopt",
        "IL", "1989-02-09", "Adopt",
        "IN", "1995-07-12", "Adopt",
        "IA", "1997-03-18", "Adopt",
        "KS", "2006-02-02", "Adopt",
        "MA", "1994-10-13", "Adopt",
        "MI", "1966-02-17", "Adopt",
        "MI", "2002-04-30", "Reject",
        "MN", "1986-10-10", "Adopt",
        "MO", "2000-11-02", "Adopt",
        "NJ", "1987-04-27", "Adopt",
        "NY", "1919-12-05", "Adopt",
        "NC", "1976-06-17", "Adopt",
        "OH", "2000-09-29", "Adopt",
        "PA", "1982-02-19", "Adopt",
        "TX", "1993-05-28", "Adopt",
        "TX", "2003-04-03", "Reject",
        "UT", "1998-01-30", "Adopt",
        "WA", "1997-12-30", "Adopt") %>%
    dplyr::mutate(across(.data$idd_date, as.Date))

usethis::use_data(idd_dates, version = 3, compress="xz", overwrite=TRUE)
