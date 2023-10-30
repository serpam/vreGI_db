

### Prepare data  --------------------------------------------
# gps_all <- readRDS(here::here("rawdata/gps_fitlered.rds"))
gps_all <- readRDS("gps_filtered.rds")
minimumdate <- as.Date("2019-10-01")

server <- function(input, output, session) {

  ### ----------------------------------------------
  # Show introduction text (Intro modal)
  observeEvent("", {
    showModal(modalDialog(
      includeHTML("intro_text.html"),
      easyClose = TRUE,
      footer = tagList(
        actionButton(inputId = "intro", label = "Introduction Tour", icon = icon("info-circle"))
      )
    ))
  })

  observeEvent(input$intro,{
    removeModal()
  })

  # Show tour
  observeEvent(input$intro,
               introjs(session,
                       options = list("nextLabel" = "Continue",
                                      "prevLabel" = "Previous",
                                      "doneLabel" = "Done"))
  )


  
  # Filter data by ENP, Ganadero and Date
  enp <- reactive({
    switch(input$enp,
      "Sierra Nevada" = "nevada",
      "Sierra de las Nieves" = "nieves",
      "Sierra de Filabres" = "filabres",
      "Cabo de Gata-Níjar" = "cabogata"
    )
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
    updateDateRangeInput(session,
      inputId = "dateRange",
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
        "http://www.ideandalucia.es/wms/mdt_2005?",
        layers = "Sombreado_10",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = '<a href="http://www.juntadeandalucia.es/institutodeestadisticaycartografía" target="_blank">Instituto de Estadística y Cartografía de Andalucía</a>',
        group = "Hillshade"
      ) |>
      addWMSTiles(
        "http://www.ideandalucia.es/wms/mta10v_2007?",
        layers = "mta10v_2007",
        options = WMSTileOptions(format = "image/png", transparent = FALSE),
        attribution = '<a href="http://www.juntadeandalucia.es/institutodeestadisticaycartografía" target="_blank">Instituto de Estadística y Cartografía de Andalucía</a>',
        group = "topo2007"
      ) |>
      addLayersControl(
        overlayGroups = c("GPS points", "minimum polygon", "kernel density", "density"),
        baseGroups = c("IGNBaseTodo", "Satellite", "Hillshade", "topo2007"),
        position = "bottomleft",
        options = layersControlOptions(collapsed = FALSE)
      )
  })





  # Update the map and heatmap based on input
  observeEvent(input$plotButton, {
    withProgress(
      message = "Plotting GPS data",
      detail = "This may take a while...",
      value = 0,
      {
        for (i in 1:15) {
          incProgress(1 / 15)
          Sys.sleep(0.25)
        }


        data <- filteredData()

        if (input$ganadero == "All") {
          pal <- colorFactor(palette = "viridis", data$codigo_gps)
        } else {
          custom_palette <- c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3", "#ff7f00", "#ffff33")
          pal <- colorFactor(palette = custom_palette, data$codigo_gps)
        }

        centro <- data |>
          st_combine() |>
          st_centroid()

        leafletProxy("mymap") |>
          clearGlLayers() |>
          clearHeatmap() |> 
          clearShapes()

        popup_point <- paste0(
          "<strong>livestock farmer:</strong> ", data$id_ganadero,
          "<br><strong>GPS:</strong> ", data$codigo_gps,
          "<br><strong>Tipo:</strong> ", data$type,
          "<br><strong>Fecha:</strong> ", data$time_stamp
        )

        leafletProxy("mymap") |>
          setView(
            lng = st_coordinates(centro)[1],
            lat = st_coordinates(centro)[2],
            zoom = 12
          ) |>
          addGlPoints(
            data = data,
            group = "GPS points",
            popup = popup_point,
            fillColor = ~ pal(codigo_gps)
          )

        if (input$showHeatmap) {
          leafletProxy("mymap") |>
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

        if (input$computePolygon > 0) {
          aux_points <- sf::st_as_sf(filteredData(), coords = c("lng", "lat"))
          aux <- terra::vect(aux_points)
          minimum_polygon <- terra::convHull(aux)

          leafletProxy("mymap") |>
            removeShape("minimum_polygon") |>
            addPolygons(
              data = minimum_polygon,
              fillColor = "transparent",
              color = "black",
              weight = 2,
              group = "minimum polygon"
            )
        }
        
        if (input$computeKde > 0) {
          aux_points_kde <- sf::st_as_sf(filteredData(), coords = c("lng", "lat"))
          kde <- eks::st_kde(aux_points_kde)
          kde95 <- st_get_contour(kde, con = 95)
          
          leafletProxy("mymap") |>
           removeShape("kernel density") |>
            addPolygons(
              data = kde95,
              fillColor = "transparent",
              color = "blue",
              weight = 2,
              group = "kernel density"
            )
        }
      }
    )
  })

  #### Download shapefiles 
  
  output$downloadShp <- downloadHandler(
    filename = 'spatial.zip',
    content = function(file) {
      
      withProgress(
        message = "Exporting shapefiles",
        detail = "This may take a while...",
        value = 0,
        {
          for (i in 1:10) {
            incProgress(1 / 10) 
            Sys.sleep(0.25)}
          
      if (length(Sys.glob("spatial.*")) > 0) {
        file.remove(Sys.glob("spatial.*"))
      }
      
      oldwd <- setwd(tempdir())
      
      points <- sf::st_as_sf(filteredData(), coords = c("lng", "lat")) 
      st_write(points, dsn = "points.shp", append = FALSE)
      
      aux <- terra::vect(points)
      mp <- terra::convHull(aux)
      minimum_polygon <- sf::st_as_sf(mp)
      st_write(minimum_polygon, dsn = "minimum_polygon.shp", append = FALSE)
      
      kde <- eks::st_kde(points)
      kde95 <- st_get_contour(kde, con = 95)
      st_write(kde95, dsn = "kde95.shp", append = FALSE)

      zip(zipfile = 'spatial.zip', files = c(Sys.glob("points.*"), 
                                             Sys.glob("minimum_polygon.*"),
                                             Sys.glob("kde95.*")))
      
      file.copy("spatial.zip", file)
      
      if (length(Sys.glob("spatial.*")) > 0) {
        file.remove(Sys.glob("spatial.*"))
      }
      
      if (length(Sys.glob("minimum_polygon.*")) > 0) {
        file.remove(Sys.glob("minimum_polygon.*"))
      }
      
      if (length(Sys.glob("kde95.*")) > 0) {
        file.remove(Sys.glob("kde95.*"))
      }
      
      setwd(oldwd)
        })
      
      showNotification("Done!", type = "warning")
    }
  )
  
  
  # Render the DataTable
  output$table <- renderDataTable({
    d <- filteredData() %>%
      dplyr::mutate(
        longitude = sf::st_coordinates(.)[, 1],
        latitude = sf::st_coordinates(.)[, 2]
      ) |>
      st_drop_geometry() |>
      dplyr::select(-enp, -qc)

    DT::datatable(
      d,
      colnames = c(
        "GPS device" = "codigo_gps",
        "Time" = "time_stamp",
        "Livestock Farmer" = "id_ganadero",
        "GPS type" = "type",
        "Animal" = "animal",
        "Herd size" = "size",
        "Lat" = "latitude",
        "Long" = "longitude"
      ),
      extensions = "Buttons",
      options = list(
        scrollX = TRUE,
        lengthMenu = c(20, 10, 15),
        paging = TRUE,
        searching = TRUE,
        fixedColumns = TRUE,
        autoWidth = FALSE,
        ordering = TRUE,
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel")
      )
    )
  })
}