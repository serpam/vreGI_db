library(here)
library(tidyverse)

# Quality control
gps <- readRDS(here::here("rawdata/gps_all.rds"))

## QC codes 
# 1 potential valid data 
# 10 lat or long == 0 


qc <- function(x) {
  x$qc <- ifelse(x$lat == 0 | x$lng == 0, 10, 1)
  return(x)
}

gps_qc <- qc(gps)

saveRDS(gps_qc, file = "rawdata/gps_qc.rds")


# Statistics 
gps_qc |> 
  group_by(qc) |> 
  summarise(n = length(qc)) |> 
  mutate(pct = n / sum(n) * 100)




###### Filter by polygon (generate polygons of potential pastoreo)
# Generate Splits by ganaderia to spatial QC 
dispositivos <-  readRDS("rawdata/dispositivos.rds") 

gps_f <- gps_qc |> 
  left_join(dispositivos)

gps_split <- split(gps_f, gps_f$id_ganadero)
purrr::iwalk(gps_split, ~write_csv(.x, file = paste0(here::here("rawdata/sites/"), .y, ".csv")))

# Then generate polygons in QGIS

### ------- 

spatial_filtered <- function(x, site, path, value_not_inside = 11){ 
  
  df <- x |> filter(id_ganadero == site) |> 
    st_as_sf(coords = c("lng", "lat"), crs = 4326)
  
  pol <- st_read(paste0(path, gsub("-", "", tolower(site)), ".shp"), 
                 quiet = TRUE) |> st_make_valid() |> st_transform(4326)
  
  df$inside <- as.numeric(sf::st_intersects(df, pol))
  
  df$qc <- ifelse(is.na(df$inside), value_not_inside, df$qc)
  
  return(df)
}


# Using purrr
sites <- c("CG-1", "CG-2", "CG-3", "FIL-1", "FIL-2", 
           "SNE-1", "SNE-2", "SNE-3", "SNE-4", "SNE-5", 
           "SNI-1", "SNI-2", "SNI-3", "SNI-4")

paths <- rep("rawdata/sites/", length(sites))

gps_f_spat <- map2_dfr(sites, paths, ~ spatial_filtered(gps_f, site = .x, path = .y)) 
gps_filtered <- gps_f_spat %>%
  dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                lat = sf::st_coordinates(.)[,2]) |> 
  st_drop_geometry() |> 
  dplyr::select(-inside)
  
  
## Old way 
# cg1 <- spatial_filtered(gps_f, site = "CG-1", path="rawdata/sites/")
# cg2 <- spatial_filtered(gps_f, site = "CG-2", path="rawdata/sites/")
# cg3 <- spatial_filtered(gps_f, site = "CG-3", path="rawdata/sites/")
# 
# fil1 <- spatial_filtered(gps_f, site = "FIL-1", path="rawdata/sites/")
# fil2 <- spatial_filtered(gps_f, site = "FIL-2", path="rawdata/sites/")
# 
# sne1 <- spatial_filtered(gps_f, site = "SNE-1", path="rawdata/sites/")
# sne2 <- spatial_filtered(gps_f, site = "SNE-2", path="rawdata/sites/")
# sne3 <- spatial_filtered(gps_f, site = "SNE-3", path="rawdata/sites/")
# sne4 <- spatial_filtered(gps_f, site = "SNE-4", path="rawdata/sites/")
# sne5 <- spatial_filtered(gps_f, site = "SNE-5", path="rawdata/sites/")
# 
# sni1 <- spatial_filtered(gps_f, site = "SNI-1", path="rawdata/sites/")
# sni2 <- spatial_filtered(gps_f, site = "SNI-2", path="rawdata/sites/")
# sni3 <- spatial_filtered(gps_f, site = "SNI-3", path="rawdata/sites/")
# sni4 <- spatial_filtered(gps_f, site = "SNI-4", path="rawdata/sites/")
# 
# 
# gps_f_spat <- bind_rows(cg1, cg2, cg3, 
#           fil1, fil2, 
#           sne1, sne2, sne3, sne4, sne5, 
#           sni1, sni2, sni3, sni4)

## Ojo la diferencia está en que existen id_ganadero con NAs
na_gan <- gps_f |> filter(is.na(id_ganadero)) |> count()

nrow(gps_f_spat) + na_gan


### Reporte gps_f_spat
gps_filtered |> 
  group_by(qc) |> 
  summarise(n = length(qc)) |> 
  mutate(pct = n / sum(n) * 100)

gps_filtered |> 
  filter(qc == 1) |> 
  rename(lng = lon) |> 
  saveRDS("rawdata/gps_filered.rds")

