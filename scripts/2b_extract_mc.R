#  ------------------------------------------------------------------------
# Title : Prepare data MC 
#    By : AJ Pérez-Luque @ajpelu
#  Date : 2022-03-18
#  ------------------------------------------------------------------------

library(here)
library(tidyverse)
library(fs)
library(glue)


# Set input folder
# input_folder <- here::here(here(), paste0("rawdata/gps_mc2023/", folder))
input_folder <- here::here("rawdata/MC")

# List all files with ..csv extension
file_names <- list.files(
  path = input_folder,
  full.names = TRUE, pattern = "*.csv", 
  recursive = TRUE
)

prepareMC <- function(d) { 
  
  x <- read_csv(d)
  
  # Contain date / datetime? 
  if ("date" %in% colnames(x) || "date_time" %in% colnames(x)) { 
  
    aux <- x 
    
    } else {
      
      if (all(c("year", "month", "day", "hour", "minute", "second") %in% colnames(x))) { 
        aux <- x |> 
          mutate(date = lubridate::make_date(as.numeric(paste0("20", year)), month, day),
             date_time = lubridate::make_datetime(as.numeric(paste0("20", year)), month, day, 
                                                hour, min = minute, sec=second))
        } else {
          stop("Date time could not be created. The file doesn't have one of year, month, day, hour, minute or second column")
        }
    }
  
  results <- aux |> 
    mutate(lat = as.numeric(lat), 
           long = as.numeric(long)) |> 
    dplyr::select(id_gps, lat, long, date, date_time)
  return(results)
}


# Prepare data 
all_gps <- file_names |> purrr::map(~prepareMC(.)) |> bind_rows()
 
 
# Exporta as separate file by months 
all_gps |> 
  mutate(year_month = format(date, "%Y_%m")) |> 
  group_by(year_month) |> 
  group_walk(.keep = TRUE, .f = ~{
      filename <- paste0("mc_", first(.x$year_month), ".csv")
                 write_csv(.x, file = paste0("rawdata/extracted/", filename))
              })





