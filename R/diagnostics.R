library(dplyr)
library(DT)
library(arrow)
library(glue)
library(ggplot2)
library(tidyr)
library(plotly)
library(htmltools)

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
        mom_ratio = round(score / lag(score, n = 1), digits=4),
        yoy_ratio = round(score / lag(score, n = 12), digits=4)
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

  raw_data = read_parquet(glue("../../../data/processed/processed_{category_name}.parquet"))

  stop_at_period_data <- raw_data %>%
      filter(REF_PERIOD <= period)

  result <- stop_at_period_data %>%
      group_by(WEEK) %>%
      summarize(
          number_of_rows     = n(),                # Count of rows
          total_sales        = round(sum(SALES), digits=2),         # Sum of column2
          # number_of_weeks    = n_distinct(WEEK),   # Unique count of column3
          ref_period         = first(REF_PERIOD),
          week_start         = first(START),
          week_end           = last(END),
          distinct_stores    = n_distinct(STORE),
          distinct_upcs      = n_distinct(UPC),
          distinct_com_codes = n_distinct(COM_CODE),
          distinct_nitems    = n_distinct(NITEM),
          distinct_zones     = n_distinct(ZONE),
          .groups            = 'drop' # Drops the grouping structure after summarizing
      )

  period_data <- result %>%
      filter(ref_period == period)

  cat("Overview statistics for the weeks included in this month's data  \n")

  print(
    htmltools::tagList(
    datatable(period_data, options = list(
    dom = 't' # i.e. Table only
  ))))

  weekly_stats <- result %>%
      filter(ref_period < period)

  # 1. Identify the numeric metrics to plot
  metrics_cols <- c("number_of_rows", "total_sales", "distinct_stores", 
                    "distinct_upcs", "distinct_com_codes", "distinct_nitems", "distinct_zones")

  # 2. Reshape historical data into a long format for faceting
  weekly_stats_long <- weekly_stats %>%
    select(all_of(metrics_cols)) %>%
    pivot_longer(cols = everything(), names_to = "Metric", values_to = "Value")

  # 3. Loop over each week in the current period
  for (i in seq_len(nrow(period_data))) {
    current_week <- period_data[i, ]
    
    # Reshape just the current week's row
    current_week_long <- current_week %>%
      select(all_of(metrics_cols)) %>%
      pivot_longer(cols = everything(), names_to = "Metric", values_to = "Value")
    
    # Build and print the plot
    p <- ggplot(weekly_stats_long, aes(x = Metric, y = Value)) +
      geom_boxplot(fill = "lightgray") +
      geom_hline(data = current_week_long, aes(yintercept = Value), color = "red", linetype = "dashed", linewidth = 1) +
      facet_wrap(~ Metric, scales = "free", ncol = 3) +
      theme_minimal() +
      theme(
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title.x = element_blank(),
        panel.spacing = unit(2, "lines")
      ) +
      labs(title = paste("Weekly Metrics Distribution"), y = "Value")

    cat(glue("  \n Week {current_week$WEEK} ({current_week$week_start} to {current_week$week_end}) in focus, compared to previous trends  \n"))
    
    print(p)
  }
}