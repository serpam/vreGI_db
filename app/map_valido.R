library(shiny)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyWidgets)
library(leaflet)
library(leaflet.extras)
library(leafgl)
library(sf)
library(tidyverse)
library(raster)
library(here)
library(readr)
library(DT)
library(shinyjs)
library(shinyhelper)

### Prepare data  --------------------------------------------
gps_all <- readRDS(here::here("rawdata/gps_filered.rds")) 
# dispositivos <-  readRDS("rawdata/dispositivos.rds") 
# gps_all <- gps |> left_join(dispositivos) |> dplyr::select(-localidad)

minimumdate <- as.Date("2019-10-01")

### UI  ------------------------------------------------------
# header
header <- shinydashboardPlus::dashboardHeader(title = "vre Grazing Intensity")

# Sidebar
sidebar <- shinydashboardPlus::dashboardSidebar(
  sidebarMenu(
    div(style="text-align:center",h4(strong("Data selection"))), 
  # tags$p(h4(strong("Data selection"))),
  
  pickerInput(
    inputId = "enp",
    label = "1. Select Protected Area",
    choices = c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"),
    multiple = FALSE,
    selected = "Sierra Nevada",
    choicesOpt = list(
      content = sprintf("<span class='badge text-bg-%s'>%s</span>",
                        c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"),
                        c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"))),
    options = pickerOptions(container = "body")
  ), 
  
  # selectInput(inputId = "enp", label = "1. Select Protected Area",
  #             choices = c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"),
  #             selected = "Sierra Nevada"),
  tags$br(),
  conditionalPanel(
    condition = "input.enp !== null", 
    selectInput(inputId = "ganadero", label = "2. Select livestock farmer",
                choices =  NULL)
  ),
  tags$br(),
  dateRangeInput(inputId = "dateRange",label = "3. Filter by date",
                 min = minimumdate, start = minimumdate,
                 end = as.Date(Sys.Date()), max = as.Date(Sys.Date())
  ),
  tags$br(),
  div(style="text-align:center",h4(strong("Plotting options"))), 
  actionButton("plotButton", "Plot data"),
  prettySwitch(
    inputId = "showHeatmap",
    label = "Show Heatmap", 
    status = "success",
    fill = TRUE, 
    value = FALSE
  )
  
  # checkboxInput("showHeatmap", "Show Heatmap", FALSE)
)
)

# Body
body <- shinydashboard::dashboardBody(
  tabBox(width = 12, id = "tabset",
         tabPanel("Map", leafglOutput("mymap", width = "100%", height = "calc(100vh - 150px)")),
         tabPanel("Table", dataTableOutput("table"))
  )
)



### Server  ------------------------------------------------------
server <- function(input, output, session) {
  
  # Filter data by ENP, Ganadero and Date 
  enp <- reactive({
    switch(input$enp, 
           'Sierra Nevada' = 'nevada', 
           'Sierra de las Nieves' = 'nieves', 
           "Sierra de Filabres" = 'filabres',
           "Cabo de Gata-Níjar" = 'cabogata')
  })
  
  observeEvent(input$enp, {
    ganaderos_enp <- gps_all |> 
      dplyr::filter(enp == enp()) |> 
      dplyr::select(id_ganadero) |> 
      unique() |> 
      pull()
    
    ganaderos <- c("All", ganaderos_enp)
    
    updateSelectInput(session, "ganadero", choices = ganaderos) 
  })
  
  observeEvent(input$ganadero, {
    datetime_ganadero <- gps_all |> 
      dplyr::filter(enp == enp() & id_ganadero == input$ganadero & time_stamp >= input$dateRange[1] & time_stamp <= input$dateRange[2])
    
    updateDateRangeInput(session, "dateRange",
                         min = minimumdate, max = as.Date(Sys.Date()),
                         start = min(datetime_ganadero$time_stamp),
                         end = max(datetime_ganadero$time_stamp)
    )
    updateDateRangeInput(session, inputId = "dateRange", 
                         min = min(datetime_ganadero$time_stamp),
                         max = max(datetime_ganadero$time_stamp)
    )
  })
  
  # Create a reactive expression for filtered data
  filteredData <- reactive({
    if (input$ganadero == "All") {
      data <- gps_all %>%
        filter(enp == enp(), time_stamp >= input$dateRange[1], time_stamp <= input$dateRange[2]) %>%
        st_as_sf(coords = c("lng", "lat"), crs = 4326)
    } else {
      data <- gps_all %>%
        filter(enp == enp(), id_ganadero == input$ganadero, time_stamp >= input$dateRange[1], time_stamp <= input$dateRange[2]) %>%
        st_as_sf(coords = c("lng", "lat"), crs = 4326)
    }
    return(data)
  })
  
  # Create the initial map
  output$mymap <- renderLeaflet({
    leaflet() |>
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
  observeEvent(input$plotButton, {
    
    withProgress(message = 'Plotting GPS data',
                 detail = 'This may take a while...', 
                 value = 0, {
                   for (i in 1:15) {
                     incProgress(1/15)
                     Sys.sleep(0.25)}
                   
    
    data <- filteredData()
    
    if (input$ganadero == "All") { 
      pal <- colorFactor(palette = "viridis", data$codigo_gps)
    } else { 
      custom_palette <- c('#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00', '#ffff33')
      pal <- colorFactor(palette = custom_palette, data$codigo_gps)
    }
    
    centro <- data |> st_combine() |> st_centroid()
    
    leafletProxy('mymap') |>
      clearGlLayers() |> 
      clearHeatmap()
    
    popup_point <- paste0("<strong>livestock farmer:</strong> ", data$id_ganadero,
                          "<br><strong>GPS:</strong> ", data$codigo_gps,
                          "<br><strong>Tipo:</strong> ", data$type,
                          "<br><strong>Fecha:</strong> ", data$time_stamp)
    
    leafletProxy('mymap') |>
      setView(
        lng = st_coordinates(centro)[1],
        lat = st_coordinates(centro)[2],
        zoom = 12
      ) |>
      addGlPoints(
        data = data,
        group = "GPS points",
        popup = popup_point,
        fillColor = ~pal(codigo_gps)
      )
    
    if (input$showHeatmap) {
      leafletProxy('mymap') |>
        addHeatmap(
          group = "density",
          data = data,
          lng = st_coordinates(data)[, "X"],
          lat = st_coordinates(data)[, "Y"],
          blur = 20,
          max = 0.6,
          radius = 15
        )
    }
  })
    })
               
               
               
  
  # Render the DataTable
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

runApp(list(ui = shinydashboard::dashboardPage(header, sidebar, body), 
            server = server), launch.browser = TRUE)
