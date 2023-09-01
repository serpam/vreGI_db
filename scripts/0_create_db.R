#  ------------------------------------------------------------------------
# Title : Create Database
#    By : AJ Pérez-Luque @ajpelu
#  Date : 2023-04-18
#  ------------------------------------------------------------------------

# Create DB

library(RSQLite)
library(tidyverse)
library(xlsx)


# Read the data dictionary
dicc_ganaderos <- readxl::read_excel("db/dicc_gps.xlsx", sheet = "dicc_ganaderos")
dicc_dispositivos <- readxl::read_excel("db/dicc_gps.xlsx", sheet = "dicc_dispositivos")
dicc_explotaciones <- readxl::read_excel("db/dicc_gps.xlsx", sheet = "dicc_explotaciones")

# Create structure of the database
con <- dbConnect(RSQLite::SQLite(), dbname = "db/db_gps.db")

## Table dicc_ganaderos
# %s(%s en la siguiente función hace referencia a cada uno de los argumentos posteriore) s

sql_statement <- sprintf(
  "CREATE TABLE %s(%s, PRIMARY KEY(%s))", "dicc_ganaderos",
  paste(names(dicc_ganaderos), collapse = ", "),
  names(dicc_ganaderos)[1]
)

dbExecute(conn = con, statement = sql_statement)
dbWriteTable(con, "dicc_ganaderos", dicc_ganaderos, append = TRUE, row.names = FALSE)

## Table dicc_explotaciones
sql_statement <- sprintf(
  "CREATE TABLE %s(%s, FOREIGN KEY(%s) REFERENCES %s(%s))", "dicc_explotaciones",
  paste(names(dicc_explotaciones), collapse = ", "),
  names(dicc_explotaciones)[1], "dicc_ganaderos",
  names(dicc_ganaderos)[1]
)

dbExecute(conn = con, statement = sql_statement)
dbWriteTable(con, "dicc_explotaciones", dicc_explotaciones, append = TRUE, row.names = FALSE)

## Table dicc_dispositivos
sql_statement <- sprintf(
  "CREATE TABLE %s(%s, PRIMARY KEY (%s) FOREIGN KEY(%s) REFERENCES %s(%s))",
  "dicc_dispositivos",
  paste(names(dicc_dispositivos), collapse = ", "),
  names(dicc_dispositivos)[4],
  names(dicc_dispositivos)[2],
  "dicc_ganaderos",
  names(dicc_ganaderos)[1]
)

dbExecute(conn = con, statement = sql_statement)
dbWriteTable(con, "dicc_dispositivos", dicc_dispositivos, append = TRUE, row.names = FALSE)

## Table datos_gps

sql_statement <- "CREATE TABLE datos_gps(
id INTEGER PRIMARY KEY AUTOINCREMENT,codigo_gps,
                      lat,
                      lng,
                      time_stamp DATETIME,
                      FOREIGN KEY(codigo_gps) REFERENCES dicc_dispositivos(codigo_gps))"


dbExecute(conn = con, statement = sql_statement)

### Schema of the database
tn <- c("datos_gps", "dicc_dispositivos", "dicc_explotaciones", "dicc_ganaderos")

library(dm)
raw_dm <- dm_from_con(con, learn_keys = FALSE)

my_dm <- raw_dm |>
  dm_select_tbl(-sqlite_sequence) |>
  dm_add_pk(dicc_ganaderos, id_ganadero) |>
  dm_add_pk(dicc_explotaciones, id_explotacion) |>
  dm_add_pk(dicc_dispositivos, codigo_gps) |>
  dm_add_pk(datos_gps, id) |>
  dm_add_fk(
    table = dicc_ganaderos,
    columns = id_ganadero,
    ref_table = dicc_dispositivos,
    ref_columns = id_ganadero
  ) |>
  dm_add_fk(
    table = dicc_dispositivos,
    columns = codigo_gps,
    ref_table = datos_gps,
    ref_columns = codigo_gps
  ) |>
  dm_add_fk(
    table = dicc_ganaderos,
    columns = id_ganadero,
    ref_table = dicc_explotaciones,
    ref_columns = id_ganadero
  ) |>
  dm_set_colors("#5B9BD5" = everything())

my_dm |> dm_draw(view_type = "all")
# We need to export the png using the viewer panel of the Rstudio
