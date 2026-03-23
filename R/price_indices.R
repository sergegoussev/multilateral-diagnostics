library(gpindex)

#' Function to return a spliced GEKS-T (i.e. CCDI)
#' 
#' @param ird is index ready data outputted homogenous_product_aggregation()
#' @return full_index 
spliced_CCDI <- function(ird) {
    # do a count of the numbef of periods
    all_periods <- unique(ird$REF_PERIOD)
    message("Calculating geks for ", length(all_periods), " periods")
    # print(all_periods)  

    # return the list of GEKS-T's for each time window
    tg <- with(ird, tornqvist_geks(PRICE, MOVE, REF_PERIOD, NITEM, window=25, na.rm = TRUE))
    message(head(tg))

    # do a mean splice on published to get a final index
    spliced_tg <- splice_index(tg, published=TRUE)
    # print("Spliced GEKS-Tornqvist index:")
    full_index <- c(1, spliced_tg)
    return(full_index)
}