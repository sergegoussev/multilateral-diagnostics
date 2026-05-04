# library(httr2)
library(arrow)
library(tidyverse)
library(glue)
library(dplyr)
library(logger)
library(jsonlite)
library(readr)

# Set the log file destination
log_appender(appender_file("operations.log"))

#' Function to download movement and upc files by category and
#' save the outputs as parquet
#' 
#' @param category_name name of the category (full name as per Booth school website)
#' @param output_path - local location where to save these files
download_category <- function(category_name, output_path) {
  #1. Read the json that stores the URLs to query
  data <- fromJSON("https://raw.githubusercontent.com/sergegoussev/sergegoussev.github.io/main/content/blogs/datasets/dominicks/urls.json")

  #2. Validate that the category chosen exists in the data
  if (!(category_name %in% names(data$category_dictionary))) {
    stop(glue("Error: '{category_name}' is not a category in the data"))
  }
  
  #Skip the step if this file has already been saved
  if (file.exists(glue("{output_path}/upc{category_name}.parquet")) == TRUE) {
    stop("This category already exists") # This is like Python's 'raise Exception'
  }

  #3. Get the product and the movement urls
  CATEGORY_SHORT <- category_name
  product_url <- glue(data$category_files$URL, data$category_files$product_URL)
  movement_url <- glue(data$category_files$URL, data$category_files$movement_URL)
  movement_url_alt <- glue(data$category_files$URL, data$category_files$movement_URL_alt)

  #4. Download and save product (upc) data
  products <- read_csv(
    product_url,
    col_types = schema(UPC = float64())
    )
  write_parquet(products, glue("{output_path}/upc{category_name}.parquet"))
  
  # 5. Download to a temporary file, unzip, and read using arrow for better performance
  temp_zip <- tempfile(fileext = ".zip")
  temp_dir <- tempfile()
  dir.create(temp_dir)
  options(timeout = 300)
  response <- HEAD(movement_url)
  if (status_code(response) == 404) {
    message("404 Found. Using alternative URL.")
    final_url <- movement_url_alt
    } else {
        final_url <- movement_url
    }
  download.file(final_url, temp_zip, mode = "wb", quiet = TRUE)
  unzipped_file <- unzip(temp_zip, exdir = temp_dir)[1]
  
  movement <- read_csv_arrow(
    unzipped_file,
    col_types = schema(UPC = float64())
    )
  cols_to_remove = c("PRICE_HEX", "PROFIT_HEX")
  movement_clean <- movement %>% select(-all_of(cols_to_remove))
  write_parquet(movement_clean, glue("{output_path}/w{category_name}.parquet"))

  # Clean up temporary files
  unlink(temp_zip)
  unlink(temp_dir, recursive = TRUE)
}


#' Function to do once time processing of week and store
#' data from its raw csv to ready to use parquet. Note these 
#' files are downloaded from the web directly
#' 
#' @param save_dir directory to save the files to
download_and_process_weeks_and_stores_data <- function(save_dir) {
    #1. Process week file
    weeks <- read_csv(
    fromJSON("https://raw.githubusercontent.com/sergegoussev/sergegoussev.github.io/main/content/blogs/datasets/dominicks/urls.json")$weeks,
    col_names = c('WEEK','START','END','SPECIAL_EVENTS')
    ) %>%
    mutate(
        START = as.Date(START,format = '%m/%d/%y'), #convert to date format
        END = as.Date(END,format = '%m/%d/%y'),     #convert to date format
        REF_PERIOD = paste(format(START, '%Y'),format(START, '%m'),sep = '-'), #reference period as string using the start of the week
        WEEK_FULLY_IN_MONTH = ifelse(months(START) == months(END),TRUE,NA),#return NA if the week straddles months
    ) %>% #create a count of the week that is cleanly within the month
    group_by(REF_PERIOD) %>%
    mutate(
        WEEK_OF_MONTH = ifelse(
        !is.na(WEEK_FULLY_IN_MONTH),
        cumsum(!is.na(WEEK_FULLY_IN_MONTH)),
        NA_integer_
        )
    ) %>%
    ungroup() %>%
    select(WEEK,REF_PERIOD,WEEK_OF_MONTH,START,END)# SPECIAL_EVENTS)
    message("weeks file downloaded and processed")
    print(head(weeks))

    print(save_dir)
    #Save the weekly file
    write_parquet(weeks, glue("{save_dir}/weeks.parquet"))
    message(glue("weeks file saved into {save_dir}"))

    stores <- read_csv(
        fromJSON("https://raw.githubusercontent.com/sergegoussev/sergegoussev.github.io/main/content/blogs/datasets/dominicks/urls.json")$stores,
        col_names = c('STORE','CITY','PRICE_TIER','ZONE','ZIP_CODE','ADDRESS')
        ) %>%
        select(STORE,PRICE_TIER,ZONE,
            # CITY,
            # ZIP_CODE,
            # ADDRESS
        )
    message("stores file downloaded and processed")

    #save the stores file
    write_parquet(stores, glue("{save_dir}/stores.parquet"))
    message(glue("stores file saved in: {save_dir}"))
}

#' Function to process the category and the supporting dataframes
#' (i.e. weeks and stores) to create a master raw data file for all 
#' transactions in the category.
#' 
#' Note: this function creates a holistic dataset of all transactions, products,
#' stores, and weekly definitions *before* pre-price index aggregation, i.e
#' before you do the praggreagation across time, geography, and products.
#' 
#' @param category_name name of the category (short form)
#' @param data_dir where the data files to process live data
#' @param save TRUE/FALSE binary to specify whether to save or not
#' @param output_dir where to save the preprocessed data
#' 
#' @return master transaction dataframe
preprocess_category_data <- function(category_name, data_dir, save=FALSE, output_dir) {
    #1. read the movement data (transactions)
    move <- read_parquet(
        glue("{data_dir}/w{category_name}.parquet")
    ) %>%
    filter(
        OK == 1 & PRICE > 0
    ) %>%
    mutate(
        SALES = PRICE * MOVE / QTY
    ) %>%
    select(WEEK, STORE, UPC, MOVE, SALES, SALE,# PROFIT
    )

    #2. read the UPC (product) data
    upc <- read_parquet(
        glue("{data_dir}/upc{category_name}.parquet")
    ) %>%
    select(COM_CODE, NITEM, UPC, DESCRIP, # SIZE
    )

    #3. Read week definitions
    weeks <- read_parquet(
        glue("{data_dir}/weeks.parquet")
    )

    #4. Read store data
    stores <- read_parquet(
    glue('{data_dir}/stores.parquet'),
    col_names = c('STORE','CITY','PRICE_TIER','ZONE','ZIP_CODE','ADDRESS')
    ) %>%
    select(STORE,PRICE_TIER,ZONE,
        # CITY,
        # ZIP_CODE,
        # ADDRESS
    )

    #5. Merge all files
    move <- move %>%
    left_join(upc,by = 'UPC'
    ) %>%
    left_join(weeks,by = 'WEEK'
    ) %>%
    left_join(stores,by = 'STORE'
    )

    # #6. Clean file
    move <- move %>%
    mutate(
        SALE = if_else(!is.na(SALE),1,0),
        COM_CODE = if_else(!is.na(COM_CODE),COM_CODE,999),
        NITEM = if_else(!is.na(NITEM) & NITEM >= 0,NITEM,UPC),
        PRICE_TIER = if_else(!is.na(PRICE_TIER),PRICE_TIER,'NA'),
        ZONE = if_else(!is.na(ZONE),ZONE,0)
    )

    #7. Save and return the file
    if (save) {
        write_parquet(move, glue("{output_dir}/processed_{category_name}.parquet"))
    }
    return(move)

}


# #' Function to do aggregation across time, outlets, and item codes. This first
# #' and critical step in any multilateral methods is key to define the 
# #' homogeneous prodcuts. The output of this step thus serves as the input for 
# #' elementary price index aggregation.
# #' 
# #' @param category_name name of the category of interest
# #' @param data_dir directory where the preprocessed cateogry data resides
# #' 
# #' @param time_sample that will be used within the month (e.g. c(1,2) will 
# #' mean that weeks 1 and 2 will be used from each month's data)
# #' @param group_by_parameters list the categories that are used to differentiate
# #' homogenous products, e.g. (COM_CODE, NITEM, STORE) will aggregate across
# #' NITEM code in each category, i.e. STOREs will be ignored.
# #' @param window dictionary that specifies the start and end of the months 
# #' that are extracted from the input data window['start'] = '1990-01-01' and 
# #' window['end'] = '1992-01-01' will pull 25 months of data
# #'  
# #' @param save TRUE/FALSE whether to save the output dataframe
# #' @param output_dir where to save the output dataframe
# #' 
# #' @output homogeneous product dataframe
# homogenous_product_aggregation <- function(
#     category_name,
#     data_dir,
#     time_sample,
#     group_by_parameters,
#     window,
#     save = FALSE,
#     output_dir = NA
# ) {
#     move = read_parquet(glue("{data_dir}/processed_{category_name}.parquet"))
#     message("data read into memory")
#     move_monthly <- move %>%
#     filter(
#         between(
#         START,
#         as.Date(window$start),
#         as.Date(window$end)
#         )
#     ) %>%
#     filter(
#         WEEK_OF_MONTH %in% time_sample # Filter for specific weeks within the month
#     ) %>%
#     group_by(across(all_of(group_by_parameters))
#     ) %>%
#     summarise(
#         MOVE = sum(MOVE),
#         SALES = sum(SALES)
#     )
#     message("aggregated")
#     # print(head(move_monthly))

#     move_monthly <- move_monthly %>%
#     group_by(
#         REF_PERIOD
#     ) %>%
#     mutate(
#         PRICE = SALES / MOVE,
#         SHARE = SALES / sum(SALES)
#     ) %>%
#     ungroup()
#     message("unit prices and sale proporitions calculated")
#     #TODO: drop unecessary columns, return and save data frame
#     if (save) {
#         write_parquet(move_monthly, glue("{output_dir}/ird_{category_name}.parquet"))
#     }
#     return(move_monthly)
# }



#' Function to do aggregation across time, outlets, and item codes. This first
#' and critical step in any multilateral methods is key to define the 
#' homogeneous prodcuts. The output of this step thus serves as the input for 
#' elementary price index aggregation.
#' 
#' @param time_sample that will be used within the month (e.g. c(1,2) will 
#'  mean that weeks 1 and 2 will be used from each month's data)
#' @param group_by_parameters list the categories that are used to differentiate
#'  homogenous products, e.g. (COM_CODE, NITEM, STORE) will aggregate across
#'  NITEM code in each category, i.e. STOREs will be ignored.
#' @param window dictionary that specifies the start and end of the months 
#'  that are extracted from the input data window['start'] = '1990-01-01' and 
#'  window['end'] = '1992-01-01' will pull 25 months of data
#'  

#' 
#' @output homogeneous product dataframe
#' 
#' 
# Core logic (Pure function - easy to test, no disk I/O required)
aggregate_homogenous_products <- function(move_data, time_sample, group_by_parameters, window) {

    move_monthly <- move_data %>%
    filter(
        between(
        START,
        as.Date(window$start),
        as.Date(window$end)
        )
    ) %>%
    filter(
        is.null(time_sample) | WEEK_OF_MONTH %in% time_sample # Filter for specific weeks within the month unless a NULL is sent
    ) %>%
    group_by(across(all_of(group_by_parameters))
    ) %>%
    summarise(
        MOVE = sum(MOVE),
        SALES = sum(SALES)
    )
    message("aggregated")
    # print(head(move_monthly))

    move_monthly <- move_monthly %>%
    group_by(
        REF_PERIOD
    ) %>%
    mutate(
        PRICE = SALES / MOVE,
        SHARE = SALES / sum(SALES)
    ) %>%
    ungroup()
    message("unit prices and sale proporitions calculated")

    return(move_monthly)
}

#' Wrapper function to do IO and to call aggregate_homogenous_products()
#'
#' @param category_name name of the category of interest
#' @param data_dir directory where the preprocessed cateogry data resides
#' @param save TRUE/FALSE whether to save the output dataframe
#' @param output_dir where to save the output dataframe
#' 
#' Other params (time_sample, group_by_parameters, window) are passed 
#'  through to aggregate_homogenous_products()
process_and_save_aggregation <- function(
    category_name,
    data_dir,
    time_sample,
    group_by_parameters,
    window,
    save = FALSE,
    output_dir = NA
    ) {
    df <- read_parquet(glue("{data_dir}/processed_{category_name}.parquet"))
    result <- aggregate_homogenous_products(df, time_sample, group_by_parameters, window)
    if (save) {
        write_parquet(result, glue(
            "{output_dir}/ird_{category_name}_timesamp_{glue_collapse(time_sample %||% 'NULL', sep = '-')}_groupby_{glue_collapse(group_by_parameters, sep = '-')}.parquet"
            ))
    }
    return(result)
}
