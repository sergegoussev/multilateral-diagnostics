library(dplyr)
library(DT)
library(arrow)
library(glue)
library(ggplot2)
library(tidyr)
library(plotly)

#' Function to render MoM and YoY table on the specific category
#' 
#' @param category_name - short name of the dominicks category of interest, e.g. "ber"
#' @param period - reference period of interest as string, e.g. "1992-02"
#' 
#' @output bar_df - dataframe of the YoY and MoM indicator
overview_table <- function(period, category_name){

    ccdi_df <- read_parquet(glue("../../../output/{category_name}_ccdi.parquet"))

    ccdi_df <- ccdi_df %>%
    arrange(period) %>% # Ensure data is ordered chronologically first
    mutate(
        mom_ratio = score / lag(score, n = 1),
        yoy_ratio = score / lag(score, n = 12)
    )

    # Extract the MoM ratio for the specific period
    mom_value <- ccdi_df %>%
    filter(period == .env$period) %>%
    pull(mom_ratio)

    # Extract the YoY ratio for the specific period
    yoy_value <- ccdi_df %>%
    filter(period == .env$period) %>%
    pull(yoy_ratio)

    # Create a small dataframe for the bar chart
    bar_df <- data.frame(
        Metric = factor(c("YoY", "MoM"), levels = c("YoY", "MoM")), # YoY at bottom, MoM on top
        Value = c(yoy_value, mom_value)
        )
    
    return(bar_df)
}



#' Function to plot key metrics as barplots for data monitoring diagnostics
#' 
#' @param category_name - short name of the dominicks category of interest, e.g. "ber"
#' @param period - reference period of interest as string, e.g. "1992-02"
#' 
#' @output
monitoring_stats <- function(period, category_name){
    raw_data = read_parquet(glue("../../../data/processed/processed_{category_name}.parquet"))

    stop_at_period_data <- raw_data %>%
    filter(REF_PERIOD <= period)

    result <- stop_at_period_data %>%
    group_by(REF_PERIOD) %>%
    summarize(
        number_of_rows             = n(),                  # Count of rows
        total_sales        = sum(SALES),         # Sum of column2
        number_of_weeks    = n_distinct(WEEK),   # Unique count of column3
        start_of_month     = first(START),
        end_of_month       = last(END),
        distinct_stores    = n_distinct(STORE),
        distinct_upcs      = n_distinct(UPC),
        distinct_com_codes = n_distinct(COM_CODE),
        distinct_nitems    = n_distinct(NITEM),
        distinct_zones     = n_distinct(ZONE),
        .groups            = 'drop' # Drops the grouping structure after summarizing
    )

    # Reshape the data to a long format, excluding date columns to avoid type conflicts
    long_result <- result %>%
    select(-start_of_month, -end_of_month) %>%
    pivot_longer(cols = -REF_PERIOD, names_to = "Metric", values_to = "Value")

    # Create faceted boxplots and add a red dashed line for the period_of_focus
    p <- ggplot(long_result, aes(x = Metric, y = Value)) +
    geom_boxplot(fill = "lightgray") +
    geom_hline(data = filter(long_result, REF_PERIOD == period), 
                aes(yintercept = Value), color = "red", linetype = "dashed", linewidth = 1) +
    facet_wrap(~ Metric, scales = "free", ncol = 3) +
    theme_minimal() +
    theme(
        axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(), 
        axis.title.x = element_blank(),
        panel.spacing = unit(2, "lines") # Adds whitespace between the faceted panels
    ) +
    labs(title = paste("Key monitoring metrics, focus on", period), y = "Value")
    
    ggplotly(p)
#   return(p)
}