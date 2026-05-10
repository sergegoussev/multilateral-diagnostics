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

    ccdi_df <- read_parquet(glue("output/{category_name}_ccdi.parquet"))

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
#' @output period_data - dataframe of the statistics for all the weeks of the month
#' @output weekly_stats - dataframe of all week's data over prior to the reference month
monitoring_stats <- function(period, category_name){

  raw_data = read_parquet(glue("data/processed/processed_{category_name}.parquet"))

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

  weekly_stats <- result %>%
      filter(ref_period < period)

  return(list(period_data=period_data, weekly_stats=weekly_stats))
}

#' Function to plot each week's satistics against the historic distribution
#' 
#' @param period_data - dataframe of the statistics for all the weeks of the month
#' @param weekly_stats - dataframe of all week's data over prior to the reference month
#' 
#' @output tagList of plotly graphs
plot_weekly_stats <- function(period_data, weekly_stats){
  # 1. Identify the numeric metrics to plot
  metrics_cols <- c(
    "number_of_rows", 
    "total_sales", 
    "distinct_stores", 
    "distinct_upcs", 
    "distinct_com_codes",
    "distinct_nitems",
    "distinct_zones")

  # 2. Reshape historical data into a long format for faceting
  weekly_stats_long <- weekly_stats %>%
    select(all_of(metrics_cols)) %>%
    pivot_longer(cols = everything(), names_to = "Metric", values_to = "Value")

  # 3. Loop over each week in the current period and save plots to a list
  plot_list <- lapply(seq_len(nrow(period_data)), function(i) {
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
      labs(
        title = glue("Week {current_week$WEEK} Distribution ({current_week$week_start})"), 
        subtitle = "Red dashed line represents current week",
        y = "Value"
      )

    # cat(glue("  \n Week {current_week$WEEK} ({current_week$week_start} to {current_week$week_end}) in focus, compared to previous trends  \n"))
    
    ggplotly(p)
  })

  return(htmltools::tagList(plot_list))
}


#' Function to plot product churn (NITEMs entering, leaving, or staying)
#' 
#' @param ird_data - Dataframe containing REF_PERIOD and NITEM
#' @return plotly object
plot_product_churn <- function(ird_data) {
  # 1. Prepare data: get set of unique NITEMs per period
  period_items <- ird_data %>%
    select(REF_PERIOD, NITEM) %>%
    distinct() %>%
    arrange(REF_PERIOD)
  
  periods <- unique(period_items$REF_PERIOD)
  
  if (length(periods) < 2) return(NULL)
  
  # 2. Calculate churn metrics iteratively
  churn_results <- lapply(seq_along(periods)[-1], function(i) {
    curr_p <- periods[i]
    prev_p <- periods[i-1]
    
    curr_items <- period_items$NITEM[period_items$REF_PERIOD == curr_p]
    prev_items <- period_items$NITEM[period_items$REF_PERIOD == prev_p]
    
    data.frame(
      REF_PERIOD = curr_p,
      Entering = length(setdiff(curr_items, prev_items)),
      Staying = length(intersect(curr_items, prev_items)),
      Left = -length(setdiff(prev_items, curr_items)) # Negative for visual distinction
    )
  }) %>% bind_rows()
  
  plot_df <- churn_results %>%
    pivot_longer(cols = c(Entering, Staying, Left), names_to = "Status", values_to = "Count") %>%
    mutate(Status = factor(Status, levels = c("Entering", "Staying", "Left")))

  p <- ggplot(plot_df, aes(x = REF_PERIOD, y = Count, fill = Status)) +
    geom_bar(stat = "identity") +
    geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
    theme_minimal() +
    scale_fill_manual(values = c("Entering" = "#2ecc71", "Staying" = "#3498db", "Left" = "#e74c3c")) +
    labs(title = "Product Churn (NITEMs) Over Time", 
         subtitle = "Comparison against previous period",
         x = "Reference Period", y = "Count of NITEMs") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(ggplotly(p))
}