#  ------------------------------------------------------------------------
# Title : Incluir datos GPS en la base de datos
#    By : AJ Pérez-Luque @ajpelu
#  Date : 2022-07-05
#  ------------------------------------------------------------------------

# Load pkgs
library(RSQLite)
library(tidyverse)
library(xlsx)
library(here)
library(glue)


# Set connection
conn <- dbConnect(RSQLite::SQLite(), dbname = here::here("db/db_gps.db"))


digitanimal <- read_csv("rawdata/extracted/digitanimal_2022_03.csv")

colnames(digitanimal)
> colnames(digitanimal)
[1] "id_collar"  "lat"        "lng"        "time_stamp"




domodis <- read_csv("rawdata/extracted/domodis_2022_11.csv")
colnames(domodis)
"familiar_name" "latitude"      "longitude"     "track_time"

mc <- read_csv("rawdata/extracted/mc_2022_03.csv")
colnames(mc)
"id_gps"     "lat"        "long"       "date"       "date_time"  "year_month"

x <- "rawdata/extracted/mc_2022_03.csv"
x <- "rawdata/extracted/domodis_2022_11.csv"


f <- basename(x)

if (grepl("mc", f)) { 
  aux <- read_csv(x) |> 
    rename(codigo_gps = id_gps, lat = lat, lng = long, time_stamp = date_time)
} else if (grepl("domodis", f)) {
  aux <- read_csv(x) |> 
    rename(codigo_gps = familiar_name, lat = latitude, lng = longitude, time_stamp = track_time)
} else if (grepl("digitanimal", f)) {
  aux <- read_csv(x) |> 
    rename(codigo_gps = id_collar, lat = lat, lng = lng, time_stamp = time_stamp)
} else {
  stop("The file does not contain the specific format")
  }


# Custom function to append data into database
appendGPStoDB <- function(file, conn, table) {
  aux_data <- read_csv(file)
  
  # Evaluate if the df has the column name "id_collar"
  if ("id_collar" %in% names(aux_data)) {
    gps_new <- aux_data %>% rename(codigo_gps = id_collar)
  } else {
    gps_new <- aux_data
  }
  
  # Tenemos problemas con ceros en lat, long, y otras que presentan latitudes y
  # longitudes algo extrañas. Solución --> filtrar por bbox (he creado un bbox de la P. Iberica)
  
  # Define the bounding box to filter out data
  long_min <- -9.49982
  long_max <- 3.352826
  lat_min <- 35.978678
  lat_max <- 43.9933088
  
  g <- gps_new %>%
    filter(between(lng, long_min, long_max)) %>%
    filter(between(lat, lat_min, lat_max))
  
  RSQLite::dbWriteTable(conn, table, g, append = TRUE, row.names = FALSE)
  
  
  # For log
  # To create log file the first time
  if (!(file.exists(here::here(here(), "db/log_incorporate.txt")))) {
    file.create(here::here(here(), "db/log_incorporate.txt"))
  }
  
  momentum <- Sys.time()
  texto <- glue::glue('
  ## Log date {momentum}
  ## File processed: {basename(file)}
  ## Date period:
  ### First record date: {min(g$time_stamp)}
  ### Last record date: {max(g$time_stamp)}
  ## Data incorporated:
  ### GPS devices: {length(unique(g$codigo_gps))}
  ### Users devices: {length(unique(g$id_user))} users
  ## {nrow(g)} records were incorporated into the database. {nrow(gps_new) - nrow(g)} records were filtered out due to spatial errors
  ### GPS devices:
  # {glue::glue_collapse(unique(g$codigo_gps), sep = ", ")}
  =============================================================')
  
  write(texto, here::here(here(), "db/log_incorporate.txt"), append = TRUE)
}


#### Datos de GPS from MAIL

myfile <- here::here("rawdata/gps_mail/all_gps_2022_08.csv")

appendGPStoDB(file = myfile, conn = conn, table = "datos_gps")


### Mejorar esto (es para incorporarlos de una vez )
filitas <- list.files(
  path = here::here("rawdata/gps_mail"),
  full.names = TRUE, pattern = "*.csv"
)

filitas <- filitas[6:14]

filitas %>% purrr::map(~ appendGPStoDB(file = .x, conn = conn, table = "datos_gps"))
### ----

#### Datos de GPS mc

myfile <- here::here("rawdata/gps_mc_processed/all_mc.csv")

appendGPStoDB(file = myfile, conn = conn, table = "datos_gps")


# End connection
RSQLite::dbDisconnect(conn)
