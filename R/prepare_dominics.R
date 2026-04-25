# import::from("src/dominicks_utils.R", download_category)
source("R/dominicks_utils.R")

#1. Download the data for each category
categories <- c("ber", "ana", "fsf", "fec", "coo", "bjc", "lnd", "frj", "tna", "oat", "tbr")

for (category in categories) {
  print(paste("Downloading ", category))
  tryCatch({
    download_category(
      category_name = category,
      output_path = "data/raw"
    )
  }, error = function(e) {
    # Note the skip in the category
    message("Skipped ", category, ": ", e$message)
  })
}

#2. Download weeks and stores
download_and_process_weeks_and_stores_data(
    save_dir = "data/raw"
)

#3. Process the data for each category
for (category in categories) {
  print(paste("Processing ", category))
  preprocess_category_data(
      category_name = category,
      data_dir = "data/raw",
      save = TRUE,
      output_dir = "data/processed"
  )
}
