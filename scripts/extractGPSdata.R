#' Extract GPS Data from ZIP Files
#'
#' This function extracts GPS data from ZIP files, processes the data, and saves it to a CSV file.
#'
#' @param input_path The path where the ZIP files are stored.
#' @param output_folder The folder where the output CSV file will be saved.
#' @param month_folder The name of the month's folder.
#' @param provider The GPS data provider (either "digitanimal" or "domodis").
#' @param our_mail The email identifier (default is "eez_serpam").
#' @param selected_variables A character vector specifying the variables to include in the output.
#'
#' @return None
#' 

extractGPSdata <- function(input_path, output_folder, month_folder, 
                           provider = c("digitanimal", "domodis"),
                           our_mail = "eez_serpam", 
                           selected_variables) { 
  
  # Input Validation
  if (missing(input_path) || !is.character(input_path) || length(input_path) == 0) {
    stop("Please provide a valid input path where the mail is stored.")
  }
  
  if (missing(output_folder) || !is.character(output_folder) || length(output_folder) == 0) {
    stop("Please provide a valid output folder to extract the data.")
  }
  
  if (missing(month_folder) || !is.character(month_folder) || length(month_folder) == 0) {
    stop("Please provide a valid name for the month's folder.")
  }
  
  provider <- match.arg(provider, c("digitanimal", "domodis"))
  
  # Create input folder path
  input_folder <- here(input_path, our_mail, month_folder)
  
  # List all files with .zip extension
  file_names <- list.files(
    path = input_folder, pattern = "*.zip",
    full.names = TRUE, recursive = TRUE, include.dirs = TRUE
  )
  
  # auxiliary function to read and select fields
  force_character_select <- function(file_path, select_fields) {
    df <- read.csv(file_path, colClasses = c(id_itm = "character", id_collar = "character", time_stamp = "POSIXct"))
    df <- df |> dplyr::select(one_of(select_fields))
    df
  }
  
  # Unzip the files and read CSV files with selected fields
  output_data <- file_names |> 
    map(~ {
      # Create a subdirectory with a unique name based on the zip file's name
      zip_basename <- tools::file_path_sans_ext(basename(.x))
      sub_output_folder <- file.path(output_folder, zip_basename)
      dir.create(sub_output_folder, recursive = TRUE, showWarnings = FALSE)
      
      # Unzip the file into the subdirectory
      unzip(zipfile = .x, exdir = sub_output_folder)
      
      # Get the list of CSV files in the subdirectory
      csv_files <- list.files(path = sub_output_folder, pattern = "*.csv", full.names = TRUE)
      
      # Read CSV files with 'id_itm' and 'id_collar' forced to character
      csv_files |> 
        map(~ force_character_select(file_path =.x, 
                                        select_fields = selected_variables))
    }) |> 
    bind_rows() 
  
  name_output_data <- paste0(provider,"_", month_folder, ".csv")
  
  # Write the output data to a CSV file
  write_csv(output_data, here(output_folder,  name_output_data))
  
  subdirs <- list.dirs(output_folder, full.names = TRUE, recursive = FALSE)
  if (length(subdirs) > 0) {
    unlink(subdirs, recursive = TRUE)
  }
}     