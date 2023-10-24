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

gps_all <- bind_rows(
  mc_all, digitanimal_all, domodis_all
)

gps_filter_spat <- gps_all |> 
  filter(lat != 0) |> 
  filter(lat < 37.22 & lat > 35.94) |>  
  filter(lng > -7.43 & lng < -1.89)

(nrow(gps_all) - nrow(gps_filter_spat))/nrow(gps_all)*100 
# 6.5 % datos erróneos gps (~152352 records)



write_csv(gps_filter_spat, "rawdata/gps_all.csv")
saveRDS(gps_filter_spat, file = "rawdata/gps_all.rds")
