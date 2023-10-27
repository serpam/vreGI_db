# Export to movebank
library(tidyverse)

readRDS("rawdata/gps_filered.rds") |> 
  write_csv("rawdata/gps_filered.csv")

gps <- readRDS("rawdata/gps_filered.rds")

gps_movebank <- gps |> 
  mutate(
    gpsType = case_when(
      type == "medición continua" ~ "internal memory",
      type == "gsm" ~ "GSM",
      type == "sigfox" ~ "Sigfox", 
      type == "satelital" ~ "satellite"),
    species = case_when(
      animal == "oveja" ~ "Ovis aries",
      animal == "cabra | oveja" ~ "Capra hircus | Ovis aries",
      animal == "cabra" ~ "Capra hircus")
    ) |> 
  dplyr::select(animalID = codigo_gps, 
         Latitude = lat, 
         Longitude = lng, 
         time_stamp,
         herdName = id_ganadero,
         herdSize = size,
         species,
         gpsType
         ) |> 
  distinct() # remove dups 


gps_movebank_selected_columns <- gps_movebank |> 
  dplyr::select(animalID, Latitude, Longitude, time_stamp)

write_csv(gps_movebank_selected_columns, "rawdata/gps_movebank.csv")

    if (input$computePolygon > 0) {
      m <- m %>% 
        addPolygons(
          data = minimum_polygon(),
          fillColor = "transparent",
          color = "black",
          weight = 2,
          group = "minimum polygon"
        )
    }
    
    # if (input$removePolygon > 0) {  # Check if the "Remove Convex Polygon" button is clicked
    #   m <- m %>% removeShape(layerId = "convex_hull")  # Remove the polygon layer
    # }
    
    mgps_movebank_accesory <- gps_movebank |> 
  dplyr::select(-Latitude, -Longitude, -time_stamp) |> 
  unique()

