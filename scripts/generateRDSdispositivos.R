# Generate RDS dispositivos 

dicc_dispositivos <- readxl::read_excel("db/dicc_gps.xlsx", sheet = "dicc_dispositivos") |> 
  dplyr::select(id_ganadero, type, codigo_gps, animal)
dicc_ganaderos <- readxl::read_excel("db/dicc_gps.xlsx", sheet = "dicc_ganaderos")
dicc_explotaciones <- readxl::read_excel("db/dicc_gps.xlsx", sheet = "dicc_explotaciones")

gan <- dicc_ganaderos |> inner_join(dicc_explotaciones) |> 
  dplyr::select(id_ganadero, enp, size) |> unique()

dispositivos <- dicc_dispositivos |> inner_join(gan) 

saveRDS(dispositivos, "rawdata/dispositivos.rds") 
