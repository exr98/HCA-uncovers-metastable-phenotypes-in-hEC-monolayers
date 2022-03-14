library(shiny)
library(shinythemes)
library(data.table)
library(ggplot2)

### function for plot

draw_plot_1 <- function(data_input, num_var_1, num_var_2, fact_var){
  if(fact_var != "Cell_Type"){
    data_input[,(fact_var):= as.factor(data_input[,get("fact_var")])]
  }
  if(num_var_1 != "Cell_Type" & num_var_2 != "Cell_Area" & fact_var != "Cell_Type"){
    ggplot(data = data_input,
           aes_string(x = num_var_1, y = num_var_2, color = fact_var)) +
      geom_point()
  }
  else if(num_var_1 != "Cell_Type" & num_var_2 != "Cell_Area" & fact_var == "Cell_Type"){
    ggplot(data = data_input,
           aes_string(x = num_var_1, y = num_var_2)) +
      geom_point()
  }
  else if(num_var_1 != "Cell_Type" & num_var_2 == "Cell_Area" & fact_var != "Cell_Type"){
    ggplot(data = data_input,
           aes_string(x = fact_var, y = num_var_1)) +
      geom_violin()
  }
  else if(num_var_1 == "Cell_Type" & num_var_2 != "Cell_Area" & fact_var != "Cell_Type"){
    ggplot(data = data_input,
           aes_string(x = fact_var, y = num_var_2)) +
      geom_violin()
  }
  else if(num_var_1 != "Cell_Type" & num_var_2 == "Cell_Area" & fact_var == "Cell_Type"){
    ggplot(data = data_input,
           aes_string(x = num_var_1)) +
      geom_histogram()
  }
  else if(num_var_1 == "Cell_Type" & num_var_2 != "Cell_Area" & fact_var == "Cell_Type"){
    ggplot(data = data_input,
           aes_string(x = num_var_2)) +
      geom_histogram()
  }
  else if(num_var_1 == "Cell_Type" & num_var_2 == "Cell_Area" & fact_var != "Cell_Type"){
    ggplot(data = data_input,
           aes_string(x = fact_var)) +
      geom_bar()
  }
}

### function for number variable summaryy tables
create_num_var_table <- function(data_input, num_var) {
  if(num_var != "Cell_Type") {
    col <- data_input[,get("num_var")]
    if(length(col)>5000) col_norm<-sample (col, 5000) else
      col_norm<-col
    norm_test <- shapiro.test(col_norm)
    statistic <- c("mean", "median", "5th percentile",
                   "95th percentile", "Shapiro statistic",
                   "Shapiro p-value")
    value <- c(round(mean(col),2), round(median(col),2),
               round(quantile(col, 0.05), 2),
               round(quantile(col, 0.95), 2),
               norm_test$statistic, norm_test$p.value)
    data.table(statistic, value)
    
  }
}

#function for factor variable
create_fact_var_table <- function(data_input, fact_var){
  if(fact_var != "Cell_Type"){
    freq_tbl <- data_input[,.N, by = get("fact_var")]
    freq_tbl <- setnames(freq_tbl, c("factor_value", "count"))
    freq_tbl
  }
}

#function for combined table 
create_combined_table <- function(data_input, num_var_1, num_var_2, fact_var){
  if(fact_var != "Cell_Type"){
    if(num_var_1 != ("Cell_Type") & num_var_2 != "Cell_Area"){
      res_tbl <- data_input[,.(correlation = cor(get("num_var_1"), get("num_var_2"))), by = fact_var]
    }
    else if(num_var_1 != "Cell_Type" & num_var_2 == "Cell_Area"){
      res_tbl <- data_input[,.(mean = mean(get("num_var_1"))), by = fact_var]
    }
    else if(num_var_1 == "Cell_Type" & num_var_2 != "Cell_Area"){
      res_tbl <- data_input[,.(mean = mean(get("num_var_2"))), by = fact_var]
    }
  }
  else if(num_var_1 != "Cell_Type" & num_var_2 != "Cell_Area"){
    res_tbl <- data.table(
      statistic = c("correlation"),
      value = c(cor(
        data_input[,get("num_var_1")],
        data_input[,get("num_var_2")])))
  }
  return(res_tbl)
}

### Trying to make type of plot selectable 



