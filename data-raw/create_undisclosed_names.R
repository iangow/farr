library(DBI)
library(dplyr, warn.conflicts = FALSE)

pg <- dbConnect(RPostgres::Postgres(), bigint = "integer")
seg_customer_hist <- tbl(pg, sql("SELECT * FROM comp_segments_hist_daily.seg_customer"))
customers <-
    seg_customer_hist %>%
    filter(ctype == "COMPANY") %>%
    collect()

undisclosed_regex <-
    customers %>%
    select(cnms) %>%
    distinct() %>%
    mutate(disclosed =
               case_when(grepl("^([0-9]+|one|two|three|four|five|six|nine|ten)\\s+customers?",
                               cnms, ignore.case = TRUE) ~ FALSE,
                         grepl("^(OEM )?Customer (- )?[A-Z]$", cnms) ~ FALSE,
                         grepl("^([0-9]+|[Tt]wo|[tT]hree)\\s+Companies$", cnms) ~ FALSE,
                         grepl("reseller", cnms, ignore.case = TRUE) ~ FALSE,
                         grepl("not\\s+rep", cnms, ignore.case = TRUE) ~ FALSE,
                         TRUE ~ NA)) %>%
    filter(!is.na(disclosed))

undisclosed_manual <-
    tibble::tribble(
        ~cnms, ~disclosed,
        "Thomson Broadcast Solutions, Customer A", TRUE,
        "Canadian Retailer", FALSE,
        "Foreign Customer", FALSE,
        "2 Home Centers", FALSE,
        "Other Domestic Distributors", FALSE,
        "Customer B", FALSE,
        "Customer C", FALSE,
        "Customer D", FALSE,
        "Other Customers", FALSE,
        "Non-Governmental Customers", FALSE,
        "1 Export Customer", FALSE,
        "4 Export Customers", FALSE,
        "5 Domestic Customers", FALSE,
        "9CUSTOMERS", FALSE,
        "Eight Customers", FALSE,
        "3Customers", FALSE,
        "All other customers", FALSE,
        "2Customers", FALSE,
        "Commercial Customer", FALSE,
        "REMAINING CUSTOMERS", FALSE,
        "All Other Customers", FALSE,
        "Individual Customers", FALSE,
        "Five Largest Customers", FALSE,
        "4 Beverage Container Mfg Customers", FALSE,
        "24 OEM Customers", FALSE,
        "Beverage Container Mfg Customer", FALSE,
        "4 ATI Customers", FALSE,
        "Non-distributor Customer", FALSE,
        "RSD Customers", FALSE,
        "One ROP Customer",  FALSE,
        "Staffing Services Customers", FALSE,
        "PEO Customers", FALSE,
        "Preferred Customer's Guild", FALSE,
        "Ten Customers-US",  FALSE,
        "Ten Customers-Global",  FALSE,
        "Foreign Customers", FALSE,
        "9 US Customers", FALSE,
        "10 International Customers", FALSE,
        "Aerospace, Transport., Industrial (ATI) Customer", FALSE,
        "10 GLOBAL CUSTOMERS", FALSE,
        "10 NORTH AMERICAN CUSTOMERS", FALSE,
        "2  CUSTOMERS", FALSE,
        "3  Customers", FALSE,
        "7 Largest Customers", FALSE,
        "Customer A", FALSE,
        "N.E.W. CUSTOMER SERVICE COMPANIES", FALSE,
        "10Customers", FALSE,
        "2 International Customers", FALSE,
        "Customer \"D\"", FALSE,
        "Customer \"C\"", FALSE,
        "Customers", FALSE,
        "2customers", FALSE,
        "3 Commercial Customers", FALSE,
        "5Customers", FALSE,
        "70CUSTOMERS", FALSE,
        "8 ROP Customers", FALSE,
        "Communications Customers", FALSE,
        "National Customer Group", FALSE,
        "Top 5 Customers", FALSE,
        "Mass retailer", FALSE,
        "EUROPEAN GOVTS", FALSE,
        "OTHER COMPANIES", FALSE,
        "2 Domestic Phone Companies", FALSE,
        "Third Party Insurance Companies", FALSE,
        "Technology Companies", FALSE,
        "Commercial Airline Companies", FALSE,
        "Insurance Companies, Government and Individuals", FALSE,
        "Transportation/Logistics Companies", FALSE,
        "Interstate Companies", FALSE,
        "Other", FALSE,
        "NOR REPORTED", FALSE,
        "Note Reported", FALSE,
        "Non reported", FALSE,
        "Nott Reported", FALSE,
        "NOTE REPORTED", FALSE,
        "NO REPORTED", FALSE,
        "No Reported", FALSE,
        "Undisclosed partner", FALSE
    )

undisclosed_names <-
    undisclosed_regex %>%
    union_all(undisclosed_manual) %>%
    distinct()

usethis::use_data(undisclosed_names,
                  version = 3, compress="xz", overwrite=TRUE)
