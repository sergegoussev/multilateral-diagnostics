# import::from("src/dominicks_utils.R", download_category)
source("R/dominicks_utils.R")

#1. Download the data for each category
# Note - the following categories are used:
# Lamboray (2021): bjc, fec, fsf, lnd, rfj, tna
# Webster et al (2019): coo (Cookies), oat (Oatmaeal), and (tbr) Toothbrushes
# 
categories <- c("bjc", "fec", "fsf", "coo", "oat", "ber")

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

# Save index ready data (i.e. homogenous products)
for (category in categories) {
  print(paste("Processing ", category))
  process_and_save_aggregation(
      category_name = category,
      data_dir = "data/processed",
      time_sample = NULL,
      group_by_parameters=c('NITEM', 'REF_PERIOD'),
      window=list(
        "start" = "1990-01-01",
        "end"   = "1997-04-01"),
      save = TRUE,
      output_dir = "data/clean"
      )
}