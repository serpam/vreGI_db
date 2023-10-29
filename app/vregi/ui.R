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
header <- shinydashboard::dashboardHeader(
  title = "vre Grazing Intensity",
  tags$li(
    a(
      strong("About"),
      height = 35,
      href = "https://github.com/serpam",
      title = "",
      targer = "_blank"
    ),
    class = "dropdown",
    tags$style(".skin-blue .main-header .logo {background-color: #43839f;}"),
    tags$style(".skin-blue .main-header .logo:hover {background-color: #43839f;}"),
    tags$style(".skin-blue .main-header .navbar {background-color: #43839f;}"),
    tags$style(".main-header {max-height: 50px;}"),
    tags$style(".main-header .logo {height: 50px;}"),
    tags$style(".sidebar-toggle {height: 50px; padding-top: 1px !important;}"),
    tags$style(".navbar {min-height:50px !important}")
  )
)

# Sidebar
sidebar <- shinydashboard::dashboardSidebar(
  width = 300,
  tags$style(".main-header .navbar {margin-left: 300px;}"),
  tags$style(".main-header .logo {width: 300px;}"),
  introjsUI(),
  sidebarMenu(
    introBox(
      div(style = "text-align:center", h3(strong("Data selection"))),
      pickerInput(
        inputId = "enp",
        label = "1. Select Protected Area",
        choices = c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"),
        multiple = FALSE,
        selected = "Sierra Nevada",
        choicesOpt = list(
          content = sprintf(
            "<span class='badge text-bg-%s'>%s</span>",
            c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar"),
            c("Sierra Nevada", "Sierra de las Nieves", "Sierra de Filabres", "Cabo de Gata-Níjar")
          )
        ),
        options = pickerOptions(container = "body")
      ),
      conditionalPanel(
        condition = "input.enp !== null",
        selectInput(
          inputId = "ganadero", label = "2. Select livestock farmer",
          choices = NULL
        )
      ),
      data.step = 1,
      data.intro = "Select the <b>Protected Natural Area</b> and <b>livestock farmer</b>."
    ),
    introBox(
      dateRangeInput(
        inputId = "dateRange", label = "3. Filter by date",
        min = minimumdate, start = minimumdate,
        end = as.Date(Sys.Date()), max = as.Date(Sys.Date())
      ),
      data.step = 2,
      data.intro = "Select a range of <b>date</b> to filter the data"
    ),
    introBox(
      div(style = "text-align:center", h3(strong("Plotting options"))),
      prettySwitch(
        inputId = "showHeatmap",
        label = "Compute Heatmap",
        status = "default",
        fill = TRUE,
        value = FALSE
      ),
      prettySwitch(
        inputId = "computePolygon",
        label = "Compute Convex Polygon",
        status = "default",
        fill = TRUE,
        value = FALSE
      ),
      data.step = 3,
      data.intro = "You can choose to compute a <b>heatmap</b> and the <b>miminum convex polygon</b> from your data selection."
    ),
    tags$br(),
    introBox(
      actionButton("plotButton", "View Data in Map"),
      data.step = 4,
      data.intro = "Each time you want view the data on map, please click the <b>View Data in Map</b> button. Click this button each time you change your selection to update the results in the map"
    ),
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
  tags$head(
    tags$style("body {font-family: Arial; font-size: 20px;}"),
    tags$style(".shiny-notification {position: fixed; top: 300px; left: 750px; font-size: 20px;
                                    width: 500px; height:100px; background-color:#43839f; 
                                    color:white;border-radius: 12px;line-height: 1;}")
  ),
  tabBox(
    width = 12, id = "tabset",
    tabPanel(
      "Map",
      introBox(
        leafglOutput("mymap", width = "100%", height = "calc(100vh - 150px)"),
        data.step = 5,
        data.intro = "The results are displayed in the <b>map</b>. You can choose the base map and different layers to display in the bottom-left legend."
      )
    ),
    tabPanel(
      title = introBox( # see this https://community.rstudio.com/t/using-the-package-rintrojs-breaks-the-display-of-panels-in-a-navbarpage/51278/3
        "Table",
        data.step = 6,
        data.intro = "The results are also displayed in table format that could be downloaded in several formats."
      ),
      dataTableOutput("table")
    )
  )
)

shinydashboard::dashboardPage(header, sidebar, body)
