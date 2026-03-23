# import::from("src/dominicks_utils.R", download_category)
source("src/dominicks_utils.R")

#1. Download the data for each category

#Beer
download_category(
  category_name = "ber",
  output_path = "data/raw"
)

#Analgetics
download_category(
  category_name = "ana",
  output_path = "data/raw"
)

#Fabric Softeners
download_category(
  category_name = "fsf",
  output_path = "data/raw"
)

#Front-end-candies
download_category(
  category_name = "fec",
  output_path = "data/raw"
)

#Cookies
download_category(
  category_name = "coo",
  output_path = "data/raw"
)

#Bottled Juices
download_category(
  category_name = "bjc",
  output_path = "data/raw"
)

# Download weeks and stores
download_and_process_weeks_and_stores_data(
    save_dir = "data/raw"
)

#2. Process the data for each category
preprocess_category_data(
    category_name = "ber",
    data_dir = "data/raw",
    save = TRUE,
    output_dir = "data/processed"
)

preprocess_category_data(
    category_name = "ana",
    data_dir = "data/raw",
    save = TRUE,
    output_dir = "data/processed"
)

preprocess_category_data(
    category_name = "fsf",
    data_dir = "data/raw",
    save = TRUE,
    output_dir = "data/processed"
)

preprocess_category_data(
    category_name = "fec",
    data_dir = "data/raw",
    save = TRUE,
    output_dir = "data/processed"
)

preprocess_category_data(
    category_name = "coo",
    data_dir = "data/raw",
    save = TRUE,
    output_dir = "data/processed"
)

preprocess_category_data(
    category_name = "bjc",
    data_dir = "data/raw",
    save = TRUE,
    output_dir = "data/processed"
)