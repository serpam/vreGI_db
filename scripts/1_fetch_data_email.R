#  ------------------------------------------------------------------------
# Title : Get GPS Data from mail
#    By : AJ Pérez-Luque @ajpelu
#  Date : 2022-03-18
#  ------------------------------------------------------------------------

# Get attachment from MAIL
library(mRpostman) # An IMAP Client for R, CRAN v1.0.0
library(here)
library(tidyverse)
library(fs)
library(glue)
source(here::here("scripts/getFromMail.R"))


# Configure connection
con <- ImapCon$new(
  url = "imaps://correo.csic.es",
  username = rstudioapi::askForSecret("mail_gps_user"),
  password = rstudioapi::askForSecret("mail_gps_pass")
)

# Select INBOX folder
con$select_folder(name = "INBOX")


## Data from DIGITANIMAL 
start_dates <- seq(as.Date("2022-01-27"),
  as.Date("2023-08-27"),
  by = "1 month"
)

end_dates <- start_dates + months(1)

# apply function of all time series 
purrr::map2(
  start_dates, end_dates,
  ~ getFromMail(
    con = con,
    start = .x,
    end = .y,
    path = here::here("rawdata/digitanimal"),
    provider = "support@digitanimal.com"
  )
)


## Data from DOMODIS
start_dates <- seq(as.Date("2022-01-27"),
                   as.Date("2023-08-27"),
                   by = "1 month"
)

end_dates <- start_dates + months(1)

# apply function of all time series 
purrr::map2(
  start_dates, end_dates,
  ~ getFromMail(
    con = con,
    start = .x,
    end = .y,
    path = here::here("rawdata/domodis"),
    provider = "data@loc.gpsganado.es"
  )
)





