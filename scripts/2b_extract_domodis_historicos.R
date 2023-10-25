#  ------------------------------------------------------------------------
# Title : Prepare data satelital antiguos 
#    By : AJ Pérez-Luque @ajpelu
#  Date : 2022-03-18
#  ------------------------------------------------------------------------

library(here)
library(tidyverse)
library(fs)
library(glue)

### Datos descargados desde la app
# Datos descargados el día "2022_11_11" desde la app. Posteriormente nos mandan los datos
# Set folder name (input data)
folder <- "descarga_aplicacion"

# Set input folder
input_folder <- here::here(here(), paste0("rawdata/domodis_historico/", folder))

# List all files with ..csv extension
file_names <- list.files(
  path = input_folder,
  full.names = TRUE, pattern = "*.txt"
)


prepareGPS_domodis_historicos <- function(x) {
  x |> 
    read_delim(delim = ";") |> 
    mutate(
      time_stamp =
        as.POSIXct(Fecha, format = "%d-%m-%Y%H:%M:%S"), 
      month = lubridate::month(time_stamp)) |> 
    dplyr::select(
      codigo_gps = Dispositivo, 
      lat = Latitud, 
      lng = Longitud,
      time_stamp
    ) |> 
    unique()
}

g <- file_names %>%
  purrr::map(prepareGPS_domodis_historicos) %>%
  reduce(rbind)


### Datos históricos previos 


folder <- "historicos"

# Set input folder
input_folder <- here::here(here(), paste0("rawdata/domodis_historico/", folder))

# List all files with ..csv extension
file_names <- list.files(
  path = input_folder,
  full.names = TRUE, pattern = "*.csv"
)

prepareGPSsatelital_historico <- function(x) {
  x |> 
    read_delim(delim = ";") |> 
    mutate(
      time_stamp =
        as.POSIXct(track_time, format = "%Y-%m-%d%H:%M:%S"), 
      month = lubridate::month(time_stamp),
      codigo_gps = stringr::str_replace(messenger_name, "-", "_")) |> 
    dplyr::select(
      codigo_gps,
      lat = latitude, 
      lng = longitude,
      time_stamp
    ) |> 
    unique()
}


h <- file_names |>
  purrr::map(prepareGPSsatelital_historico) |>
  reduce(rbind) |> 
  filter(codigo_gps != "GGPS_3")


domodis_historicos <- bind_rows(g, h)


write_csv(domodis_historicos,
         file = here::here("rawdata/domodis_historico/domodis_historicos.csv"))














