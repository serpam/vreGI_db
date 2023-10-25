# Generate data for ganaderias 

# Get GPS
domodis_files <- list.files(
  path = here::here("rawdata/extracted/"),
  full.names = TRUE, pattern = "domodis"
) 

domodis_all <- domodis_files |> map(read_csv) |> reduce(bind_rows) |> 
  rename(codigo_gps = familiar_name, lat = latitude, lng = longitude, time_stamp = track_time)


digitanimal_files <- list.files(
  path = here::here("rawdata/extracted/"),
  full.names = TRUE, pattern = "digitanimal"
) 

digitanimal_all <- digitanimal_files |>  map(read_csv) |> reduce(bind_rows) |> 
  rename(codigo_gps = id_collar, lat = lat, lng = lng, time_stamp = time_stamp)


mc_files <- list.files(
  path = here::here("rawdata/extracted/"),
  full.names = TRUE, pattern = "mc"
) 

mc_all <- mc_files |>  map(read_csv) |> reduce(bind_rows) |> 
  rename(codigo_gps = id_gps, lat = lat, lng = long, time_stamp = date_time) |> 
  dplyr::select(-date, -year_month)

domodis_historicos <- read_csv(here::here("rawdata/domodis_historico/domodis_historicos.csv"))

gps_all <- bind_rows(
  mc_all, digitanimal_all, domodis_all, domodis_historicos
)


# write_csv(gps_filter_spat, "rawdata/gps_all.csv")
saveRDS(gps_all, file = "rawdata/gps_all.rds")




