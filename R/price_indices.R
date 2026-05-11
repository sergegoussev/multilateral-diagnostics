library(gpindex)
library(PriceIndices)
library(remotes)
library(lubridate)

#' Function to return a spliced GEKS-T (i.e. CCDI)
#' 
#' @param ird is index ready data outputted homogenous_product_aggregation()
#' @param window = 25 is the window over which calculation is done. Optional
#' 
#' @return full_index 
spliced_CCDI <- function(ird, window=25) {
    # do a count of the numbef of periods
    all_periods <- unique(ird$REF_PERIOD)
    message("Calculating geks for ", length(all_periods), " periods")
    # print(all_periods)  

    # return the list of GEKS-T's for each time window
    tg <- with(ird, tornqvist_geks(PRICE, MOVE, REF_PERIOD, NITEM, window=window, na.rm = TRUE))
    message(head(tg))

    # do a mean splice on published to get a final index
    spliced_tg <- splice_index(tg, published=TRUE)
    # print("Spliced GEKS-Tornqvist index:")
    full_index <- c(1, spliced_tg)
    return(full_index)
}

#' Function to calcualte and return dataframe of produt contributions for MoM

GEKS_contributions <- function(category_name, period){
  ird <- read_parquet(glue("data/clean/ird_{category_name}_timesamp_NULL_groupby_NITEM-REF_PERIOD.parquet"))

  ird_for_m_decomp <- data.frame(
    time = as.Date(paste0(ird$REF_PERIOD, "-01")), # Convert "YYYY-MM" to "YYYY-MM-01" and then to Date
    prices = ird$PRICE,
    quantities = ird$MOVE,
    prodID = as.factor(ird$NITEM) # Convert NITEM to a factor, as recommended
  )

  start_period <- format(ymd(paste0(period, "-01")) %m-% months(24), "%Y-%m")

  x <- m_decomposition(ird_for_m_decomp, 
    start=start_period, 
    end=period,
    # wstart="1993-02",
    window=25,
    formula=c("ccdi")
    )$multiplicative

  x <- x %>%
    mutate(CCDI = log(CCDI)) %>%
    rename(log_contribution = CCDI)

  data_up_to_period <- ird %>%
        filter(REF_PERIOD <= period)

  unit_price_changes <- item_price_ratio_table(data_up_to_period, period)

  merged_data <- merge(
    x, 
    unit_price_changes, 
    by.x = "product", by.y = "NITEM")

  return(merged_data)

}