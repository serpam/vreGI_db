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
library(rintrojs)



### Prepare data  --------------------------------------------
gps_all <- readRDS("gps_filered.rds")
minimumdate <- as.Date("2019-10-01")

### UI  ------------------------------------------------------
# header
header <- shinydashboardPlus::dashboardHeader(
  title = "vre Grazing Intensity",
  tags$li(
    a(
      strong("About"),
      height = 35,
      href = "https://github.com/serpam",
      title = "",
      targer = "_blank"
    ),
    class = "dropdown"
  )
)

# Sidebar
sidebar <- shinydashboardPlus::dashboardSidebar(
  sidebarMenu(
    div(style = "text-align:center", h4(strong("Data selection"))),
    # tags$p(h4(strong("Data selection")))
    pickerInput(
      inputId = "enp",
      label = "1. Select Protected Area",
      choices = c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"),
      multiple = FALSE,
      selected = "Sierra Nevada",
      choicesOpt = list(
       # style = rep(("color: green; background: lightgrey; font-weight: bold;"), 4)
        content = sprintf(
          "<span class='badge text-bg-%s'>%s</span>",
          c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"),
          c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar")
        )
      ),
      options = pickerOptions(container = "body")
    ),
    tags$br(),
    conditionalPanel(
      condition = "input.enp !== null",
      selectInput(
        inputId = "ganadero", label = "2. Select livestock farmer",
        choices = NULL
      )
    ),
    tags$br(),
    dateRangeInput(
      inputId = "dateRange", label = "3. Filter by date",
      min = minimumdate, start = minimumdate,
      end = as.Date(Sys.Date()), max = as.Date(Sys.Date())
    ),
    tags$br(),
    div(style = "text-align:center", h4(strong("Plotting options"))),
    tags$br(),
    prettySwitch(
      inputId = "showHeatmap",
      label = "Compute Heatmap",
      status = "default",
      fill = TRUE,
      value = FALSE
    ),
    tags$br(),
    prettySwitch(
      inputId = "computePolygon",
      label = "Compute Convex Polygon",
      status = "default",
      fill = TRUE,
      value = FALSE
    ),
    tags$br(),
    actionButton("plotButton", "View Data in Map"), 
    tags$br(),
    tags$br(),
    div(
      style = "text-align:center",
      tags$img(src = "serpam.png", width = "200px", height = "200px")
    ),
    tags$br(),
    div(
      style = "text-align:center",
      tags$img(src = "sumhal_nofondo.png", width = "200px", height = "150px")
    )
  )
)

# Body
body <- shinydashboard::dashboardBody(
  # tags$head(
  #   tags$link(rel = "stylesheet", type = "text/css", href = "serpam.css")
  # ),
  # use_theme(mytheme),
  tabBox(
    width = 12, id = "tabset",
    tabPanel("Map", leafglOutput("mymap", width = "100%", height = "calc(100vh - 150px)")),
    tabPanel("Table", dataTableOutput("table"))
  )
)

shinydashboard::dashboardPage(header, sidebar, body, skin = "green")
