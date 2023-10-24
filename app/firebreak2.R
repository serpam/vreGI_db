library(shiny)
library(leaflet)
library(leaflet.extras)
library(leafgl)
library(sf)
library(tidyverse)
library(raster)
library(here)
library(readr)
library(DT)
library(terra)

# Read the data
gps <- read_csv(here::here("rawdata/sne1_filtered.csv")) %>% dplyr::select(-id)

### 11970 datos con fecha NA (un 28 %) !! todos GSM
gps_points <- st_as_sf(gps, coords = c("lng", "lat"), crs = 4326)

# Shiny App
ui <- bootstrapPage(
  tags$style(type = "text/css", "
             html, body {
              width: 100%;
              height: 100%;
             }
             
             .transparent-panel { 
              background-color: transparent !important;
             }
             "),
  navbarPage(
    title = "Livestock and Biodiversity",
    tabPanel(
      "Map",
      leafglOutput("mymap", width = "100%", height = "calc(100vh - 80px)"),
      absolutePanel(
        class = "transparent-panel",
        fixed = TRUE,
        top = 60,
        right = 20,
        left = "auto",
        bottom = "auto",
        width = 330,
        height = "auto",
        
        selectInput(
          inputId = "ganadero",
          label = "Livestock farmer",
          choices = c("All", unique(gps_points$id_ganadero))
        ),
        
        dateRangeInput(
          inputId = "dateRange",
          label = "Filter by date",
          min = as.Date('2021-12-31'),
          start = as.Date('2021-12-31'),
          end = as.Date(Sys.Date()),
          max = as.Date(Sys.Date())
        ), 
        actionButton("computePolygon", "Compute Convex Polygon"),
        actionButton("removePolygon", "Remove Convex Polygon") 
      )
    ),
    tabPanel(
      "Table",
      dataTableOutput("table")
    )
  )
)

server <- function(input, output, session) {
  
  # Filter by livestock farmer
  ganadero_data <- reactive({ 
    if (input$ganadero == "All") { 
      gps_points
    } else {
      gps_points %>% dplyr::filter(id_ganadero == input$ganadero)
    }
  })
  
  paleta <- reactive({
    if (input$ganadero == "All") {
      pal <- colorFactor(palette = "viridis", gps_points$codigo_gps)
    } else {
      custom_palette <- c('#e41a1c','#377eb8','#4daf4a','#984ea3','#ff7f00','#ffff33')
      pal <- colorFactor(palette = custom_palette, ganadero_data()$codigo_gps)
    }
  })
  
  # Reactive expression for the data subsetted by the user's date range selection
  filteredData <- reactive({
    ganadero_data()  %>% dplyr::filter(time_stamp >= input$dateRange[1] & time_stamp <= input$dateRange[2])
  })
  
  observeEvent(input$ganadero, {
    updateDateRangeInput(session,
                         inputId = "dateRange",
                         min = as.Date('2021-12-31'),
                         max = as.Date(Sys.Date()),
                         start = min(ganadero_data()$time_stamp),
                         end = max(ganadero_data()$time_stamp))
  })
  
  # Center the map on the selected features 
  centro <- reactive({
    coordinates(as(extent(filteredData()), "SpatialPolygons")) %>% colMeans
  })
  
  convexHull <- eventReactive(input$computePolygon, {
    # Calculate convex hull directly using the chull function
    aux_points <- sf::st_as_sf(filteredData(), coords = c("lng", "lat"))
    aux <- terra::vect(aux_points)
    hull <- terra::convHull(aux)
    return(hull)
  })
  
  
  # Create the map 
  output$mymap <- renderLeaflet({
    m <- leaflet(data = filteredData()) %>%
      addWMSTiles(
        baseUrl = "http://www.ign.es/wms-inspire/ign-base?",
        layers = "IGNBaseTodo",
        group = "Basemap",
        attribution = '© <a href="http://www.ign.es/ign/main/index.do" target="_blank">Instituto Geográfico Nacional de España</a>'
      ) %>% 
      addProviderTiles("Esri.WorldImagery", group = "Satellite") %>% 
      addWMSTiles('http://www.ideandalucia.es/wms/mdt_2005?',
                  layers = 'Sombreado_10',
                  options = WMSTileOptions(format = "image/png", transparent = TRUE),
                  attribution = '<a href="http://www.juntadeandalucia.es/institutodeestadisticaycartografía" target="_blank">Instituto de Estadística y Cartografía de Andalucía</a>', 
                  group = 'Hillshade') %>% 
      addWMSTiles('http://www.ideandalucia.es/wms/mta10v_2007?',
                  layers = 'mta10v_2007',
                  options = WMSTileOptions(format = "image/png", transparent = FALSE),
                  attribution = '<a href="http://www.juntadeandalucia.es/institutodeestadisticaycartografía" target="_blank">Instituto de Estadística y Cartografía de Andalucía</a>',
                  group = 'topo2007') %>% 
      addLayersControl(overlayGroups = c("pts","density", "convex_hull"),
                       baseGroups = c("IGNBaseTodo","Satellite", "Hillshade","topo2007"), 
                       position = "bottomright")
  
    if (input$computePolygon > 0) {
      m <- m %>% 
        addPolygons(
          data = convexHull(),
          fillColor = "transparent",
          color = "black",
          weight = 2,
          group = "convex_hull"
        )
    }
    
    if (input$removePolygon > 0) {  # Check if the "Remove Convex Polygon" button is clicked
      m <- m %>% removeShape(layerId = "convex_hull")  # Remove the polygon layer
    }
    
    m
  })
  
  observe({
    popup_point <- paste0("<strong>Livestock farmer:</strong> ", filteredData()$id_ganadero,
                          "<br><strong>GPS:</strong> ", filteredData()$codigo_gps,
                          "<br><strong>Type:</strong> ", filteredData()$type,
                          "<br><strong>Date:</strong> ", filteredData()$time_stamp)
    pal <- paleta()
    
    leafletProxy('mymap') %>%
      setView(
        lng = as.numeric(centro()[1]),
        lat = as.numeric(centro()[2]),
        zoom = 12
      ) %>% 
      addGlPoints(data = filteredData(), 
                  group = "pts", 
                  popup = popup_point, 
                  fillColor = ~pal(codigo_gps)) %>%
      clearHeatmap() %>%
      addHeatmap(
        group = "density", 
        data = filteredData(), 
        lng = st_coordinates(filteredData())[, "X"],
        lat = st_coordinates(filteredData())[, "Y"],
        blur = 20,
        max = 0.6,
        radius = 15
      )
    
    if (input$computePolygon > 0) {
      leafletProxy('mymap') %>%
        clearShapes() %>%
        addPolygons(
          data = convexHull(),
          fillColor = "transparent",
          color = "black",
          weight = 2,
          group = "convex_hull"
        )
    }
    
    if (input$removePolygon > 0) {
      leafletProxy('mymap') %>%
      removeShape('convex_hull')
    }
    
    
    
    
    
  })
  
  output$table <- renderDataTable({
    DT::datatable(filteredData(), 
                  extensions = 'Buttons', 
                  options = list(
                    scrollX = TRUE, 
                    lengthMenu = c(5, 10, 15),
                    paging = TRUE, 
                    searching = TRUE,
                    fixedColumns = TRUE, 
                    autoWidth = TRUE,
                    ordering = TRUE, 
                    dom = 'Bfrtip',
                    buttons = c('copy', 'csv', 'excel')
                  ))
  })
}

shinyApp(ui, server)
