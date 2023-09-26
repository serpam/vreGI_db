#  ------------------------------------------------------------------------
# Title : Extract GPS data from ZIP files
#    By : AJ Pérez-Luque @ajpelu
#  Date : 2022-03-18
#  ------------------------------------------------------------------------

library(here)
library(tidyverse)
library(fs)
library(glue)
source(here::here("scripts/extractGPSdata.R"))

# s <- c("id_collar", "lat", "lng", "time_stamp")
# input_path <- here::here("rawdata/digitanimal")
# output_folder <- here::here("rawdata/extracted")
# 

basename(list.dirs(here::here("rawdata/digitanimal/eez_serpam"), recursive = FALSE)) |> 
  purrr::map(~extractGPSdata(input_path = here::here("rawdata/digitanimal"),
                             output_folder = here::here("rawdata/extracted"),
                             month_folder = .x,
                             provider = 'digitanimal', 
                             selected_variables = c("id_collar", "lat", "lng", "time_stamp")))


basename(list.dirs(here::here("rawdata/domodis/eez_serpam"), recursive = FALSE)) |> 
  purrr::map(~extractGPSdata(input_path = here::here("rawdata/domodis"),
                             output_folder = here::here("rawdata/extracted"),
                             month_folder = .x,
                             provider = 'domodis', 
                             selected_variables = c("familiar_name", "latitude", "longitude", "track_time")))






extractGPSdata(input_path = here::here("rawdata/digitanimal"),
               output_folder = here::here("rawdata/extracted"),
               month_folder = "2023_04",
               provider = 'digitanimal', 
               selected_variables = c("id_collar", "lat", "lng", "time_stamp"))



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








   
   
   
   

   
   
   |>
     list.files(path = output_folder, pattern = "*.csv")
     
      map_df(~read_csv(l)))
      
list.files(path = output_folder, pattern = "*.csv", full.names = TRUE) %>%
  map(read.csv)
    
    
    
    
    # Rename files using GPS user id
    gps_usuario <- str_remove(basename(file_names[i]), pattern = "\ .*")
    file.rename(
      from = here::here(output_folder, "history.csv"),
      to = here::here(output_folder, paste0(gps_usuario, ".csv"))
    )
    
    # Remove junk files (sh)
    junk_files <- dir(path = output_folder, pattern = "history.*")
    file.remove(file.path(output_folder, junk_files))
  }
  
  
  
  
  
  
  }





# Set month
month_date <- "2023_06"

# Set input and output folder
##### To review change folder
input_folder <- here::here(here(), paste0("rawdata/gps_mail/eez_serpam/", month_date))
output_folder <- fs::dir_create(here::here(here(), "rawdata/gps_mail/extracted"))

# List all files with .zip extension
file_names <- list.files(
  path = input_folder,
  full.names = TRUE, recursive = TRUE,
  include.dirs = TRUE, pattern = "*.zip"
)


for (i in 1:length(file_names)) {
  
  # Unzip files
  unzip(zipfile = file_names[i], exdir = output_folder)
  
  # Rename files using GPS user id
  gps_usuario <- str_remove(basename(file_names[i]), pattern = "\ .*")
  file.rename(
    from = here::here(output_folder, "history.csv"),
    to = here::here(output_folder, paste0(gps_usuario, ".csv"))
  )
  
  # Remove junk files (sh)
  junk_files <- dir(path = output_folder, pattern = "history.*")
  file.remove(file.path(output_folder, junk_files))
}


a <- list.files(path = output_folder, full.names = TRUE, pattern = ".csv")

data <- a %>%
  map(read_csv) %>%
  reduce(rbind) %>%
  dplyr::select(id_collar, id_itm, id_user, lat, lng, time_stamp, month)


# Remove all data
fs::dir_delete(output_folder)

write_csv(data, here::here(paste0("rawdata/gps_mail/all_gps_", month_date, ".csv")))


# To create log file the first time
if (!(file.exists(here::here(here(), "rawdata/gps_mail/eez_serpam/log-process-gsm.md")))) {
  file.create(here::here(here(), "rawdata/gps_mail/eez_serpam/log-process-gsm.md"))
}

# For log
momentum <- Sys.time()
texto <- glue::glue(
  '# Log date {momentum}
  
  ## Files processed:
  - n = {length(file_names)}
  - **IDs** of the files processed: {glue::glue_collapse(basename(file_names), sep = ", ")}

  ## Temporal coverage
  - **Date period**: {month_date}
  - **First record date**: {min(data$time_stamp)}
  - **Last record date**: {max(data$time_stamp)}

  ## GPS devices processed: 
  - n = {length(unique(data$id_collar))}
  - **Users devices**: {length(unique(data$id_user))} users
  - {nrow(data)} records were processed
  - GPS devices: {glue::glue_collapse(unique(data$id_collar), sep = ", ")}

  ### Output data: 
  - `{paste0("rawdata/gps_mail/all_gps_", month_date, ".csv")}`
  
  '
)

write(texto, here::here(here(), "rawdata/gps_mail/eez_serpam/log-process-gsm.md"),
      append = TRUE
)
