library(shiny)
library(shinydashboard)
library(leaflet)
library(leaflet.extras)
library(leafgl)
library(sf)
library(tidyverse)
library(raster)
library(here)
library(readr)
library(DT)

# read the data
# gps <- read_csv(here::here("rawdata/sne1_filtered.csv")) |> dplyr::select(-id)
gps <- readRDS(here::here("rawdata/cg_filtered.rds"))

### 11970 datos con fecha NA (un 28 %) !! todos GSM
gps_points <- st_as_sf(gps, coords = c("lng", "lat"), crs = 4326)

# header
header <- shinydashboard::dashboardHeader(
  title = "vre Grazing Intensity"
)

# Sidebar
sidebar <- shinydashboard::dashboardSidebar(
  tags$p(tags$style(".right-align { text-align: right; }")),  # CSS embedded here
  tags$br(),
  tags$p(class = "right-align", h4(strong("1. Select livestock farmer")),  # Add the checkbox here
  selectInput(inputId = "ganadero", label = "Livestock farmer",
              choices = c("All", unique(gps_points$id_ganadero)),
              selected = "All"),
  tags$br(),
  tags$p(h4(strong("2. Select Time period"))),
  dateRangeInput(
    inputId = "dateRange",
    label = "Filter by date",
    min = as.Date("2021-12-31"),
    start = as.Date("2021-12-31"),
    end = as.Date(Sys.Date()),
    max = as.Date(Sys.Date())
  ),
  tags$br(),
  actionButton("plotButton", "Plot the data"),
  checkboxInput("showHeatmap", "Show Heatmap", FALSE))
)

# Body
body <- shinydashboard::dashboardBody(
  tabBox(width = 12, id = "tabset",
    tabPanel("Map", leafglOutput("mymap", width = "100%", height = "calc(100vh - 150px)")),
    tabPanel("Table", dataTableOutput("table"))
  )
)

server <- function(input, output, session) {
  # Filter data by Ganadero
  ganadero_data <- reactive({
    if (input$ganadero == "All") {
      gps_points
    } else {
      gps_points |> dplyr::filter(id_ganadero == input$ganadero)
    }
  })
  
  # Filter by date
  filteredData <- reactive({
    ganadero_data() |>
      dplyr::filter(time_stamp >= input$dateRange[1] & time_stamp <= input$dateRange[2])
  })
  
  observeEvent(input$ganadero, {
    updateDateRangeInput(
      session,
      inputId = "dateRange",
      min = as.Date("2021-12-31"),
      max = as.Date(Sys.Date()),
      start = min(ganadero_data()$time_stamp),
      end = max(ganadero_data()$time_stamp)
    )
    updateDateRangeInput(
      session,
      inputId = "dateRange",
      min = min(ganadero_data()$time_stamp),
      max = max(ganadero_data()$time_stamp)
    )
  })
  
  # Center the map to the selected features
  centro <- reactive({
    coordinates(as(extent(filteredData()), "SpatialPolygons"))
  })
  
  paleta <- reactive({
    if (input$ganadero == "All") {
      pal <- colorFactor(palette = "viridis", gps_points$codigo_gps)
    } else {
      custom_palette <- c('#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00', '#ffff33')
      pal <- colorFactor(palette = custom_palette, ganadero_data()$codigo_gps)
    }
  })
  
  # Create the initial map
  output$mymap <- renderLeaflet({
    leaflet(data = filteredData()) |>
      setView(lng = -3.9822, lat = 37.3846, zoom = 8) |>
      addWMSTiles(
        baseUrl = "http://www.ign.es/wms-inspire/ign-base?",
        layers = "IGNBaseTodo",
        group = "Basemap",
        attribution = '© <a href="http://www.ign.es/ign/main/index.do" target="_blank">Instituto Geográfico Nacional de España</a>'
      ) |>
      addProviderTiles("Esri.WorldImagery", group = "Satellite") |>
      addWMSTiles(
        'http://www.ideandalucia.es/wms/mdt_2005?',
        layers = 'Sombreado_10',
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = '<a href="http://www.juntadeandalucia.es/institutodeestadisticaycartografía" target="_blank">Instituto de Estadística y Cartografía de Andalucía</a>',
        group = 'Hillshade'
      ) |>
      addWMSTiles(
        'http://www.ideandalucia.es/wms/mta10v_2007?',
        layers = 'mta10v_2007',
        options = WMSTileOptions(format = "image/png", transparent = FALSE),
        attribution = '<a href="http://www.juntadeandalucia.es/institutodeestadisticaycartografía" target="_blank">Instituto de Estadística y Cartografía de Andalucía</a>',
        group = 'topo2007'
      ) |>
      addLayersControl(overlayGroups = c("GPS points", "density"),
                       baseGroups = c("IGNBaseTodo", "Satellite", "Hillshade", "topo2007"),
                       position = "bottomright")
  })
  
  # Update the map and heatmap based on input
  observe({
    leafletProxy('mymap') |>
      clearMarkers() |>
      clearHeatmap()
    
    popup_point <- paste0("<strong>livestock farmer:</strong> ", filteredData()$id_ganadero,
                          "<br><strong>GPS:</strong> ", filteredData()$codigo_gps,
                          "<br><strong>Tipo:</strong> ", filteredData()$type,
                          "<br><strong>Fecha:</strong> ", filteredData()$time_stamp)
    pal <- paleta()
    
    leafletProxy('mymap') |>
      setView(
        lng = as.numeric(centro()[1]),
        lat = as.numeric(centro()[2]),
        zoom = 12
      ) |>
      addGlPoints(
        data = filteredData(),
        group = "GPS points",
        popup = popup_point,
        fillColor = ~pal(codigo_gps)
      )
    
    if (input$showHeatmap) {
      leafletProxy('mymap') |>
        addHeatmap(
          group = "density",
          data = filteredData(),
          lng = st_coordinates(filteredData())[, "X"],
          lat = st_coordinates(filteredData())[, "Y"],
          blur = 20,
          max = 0.6,
          radius = 15
        )
    }
  })
  
  output$table <- renderDataTable({
    DT::datatable(
      filteredData(),
      extensions = 'Buttons',
      options = list(
        scrollX = TRUE,
        lengthMenu = c(25, 10, 15),
        paging = TRUE,
        searching = TRUE,
        fixedColumns = TRUE,
        autoWidth = TRUE,
        ordering = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      )
    )
  })
}

shinyApp(ui = shinydashboard::dashboardPage(header, sidebar, body), server)
