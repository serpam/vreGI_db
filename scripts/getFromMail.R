#' Fetches emails, extracts data, and logs the process.
#'
#' This function connects to an email server, searches for emails based on given
#' criteria, extracts data and attachments from the emails, moves the data to a
#' designated folder, and logs the process in a markdown file.
#'
#' @param con An email connection object.
#' @param start Start date for searching emails (YYYY-MM-DD format).
#' @param end End date for searching emails (YYYY-MM-DD format).
#' @param path Path to the base directory where data and logs will be stored.
#' @param provider The email provider to search for in the "FROM" field.
#' @param name_folder Optional. Name of the folder to store extracted data.
#'                    If not provided, it will be in the format YYYY_MM based on \code{start}.
#' @param our_mail Optional. The email account to interact with. Default is "eez_serpam".
#' 
#' @return None
#' 
#' @details This function connects to the provided email server, searches for emails
#' from the specified provider between the specified dates, and extracts email bodies
#' and attachments. Extracted data is moved to a folder named based on \code{name_folder}.
#' The process is logged in a markdown file, creating the log file if it doesn't exist.
#'
#' @importFrom fs dir_copy dir_delete
#' @importFrom glue glue glue_collapse
#' @importFrom here here
#' 
#' @examples
#' # Establish an email connection using appropriate credentials
#' con <- ... # Establish your email connection
#' 
#' # Fetch and process emails
#' getFromMail(con, "2023-01-01", "2023-08-31", "~/email_data", "example.com")
#'
#' @export
getFromMail <- function(con, start, end, path, 
                        provider, name_folder = NULL, 
                        our_mail = "eez_serpam") {
  if (is.null(name_folder)) {
    name_folder <- format.Date(start, "%Y_%m")
  }
  
  if (is.null(path)) {
    stop("Please provide a path to store the mails")
  }
  
  # Set dir to store mails
  setwd(path)
  
  result <- con$search(
    request = AND(
      string(expr = provider, where = "FROM"),
      since(date_char = format.Date(start, "%d-%b-%Y")),
      before(date_char = format.Date(end, "%d-%b-%Y"))
    )
  )
  
  if (all(is.na(result))) {
    message("No results found with the given criteria")
  } else {
    fetched_data <- result |>
      con$fetch_body(write_to_disk = TRUE) |>
      con$get_attachments(override = TRUE)
    
    if (length(fetched_data) > 0) {
      # How many mails were read and extracted
      inbox_path <- here(path, our_mail, "INBOX")
      file_names <- list.files(path = inbox_path, pattern = "*.txt")
      
      if (length(file_names) > 0) {
        # Move all data to a specific folder
        dir_copy(inbox_path, here(path, our_mail, name_folder))
        
        # Remove all data
        dir_delete(inbox_path)
        
        # Log creation
        log_path <- here(path, our_mail, "log-getfrommail.md")
        
        if (!file.exists(log_path)) {
          file.create(log_path)
        }
        
        momentum <- Sys.time()
        log_text <- glue::glue(
          "## Log date {momentum}
          - **Period**: the gps data corresponds to {name_folder}
          - Files extracted from mail account: {length(file_names)}
          - IDs of mail extracted: {glue::glue_collapse(str_remove(str_remove(file_names, 'body'), '.txt'), sep = ', ')}.\n"
        )
        
        write(log_text, log_path, append = TRUE)
      } else {
        message("No text files found in the fetched data")
      }
    } else {
      message("No data fetched")
    }
  }
}

