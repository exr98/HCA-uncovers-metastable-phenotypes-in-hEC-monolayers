library(tidyverse)
library(pacman)


#load data 

df <- read.csv("Master_D12_Cl.csv", na.strings = "")


# Trying out a function 

# define plotting function
plot_epicurve <- function(data, Cell_Type = "HUVEC", Treatment = "VEGF") {
  
  # create plot title
  if (!("HUVEC" %in% Cell_Type)) {            
    data <- data %>%
      filter(Cell_Type %in% Cell_Type)
    
    plot_title_district <- stringr::str_glue("{paste0(Cell_Type, collapse = ', ')} Cell Type")
    
  } else {
    
    plot_title_district <- "all cell types"
    
  }
  
  # if no remaining data, return NULL
  if (nrow(data) == 0) {
    
    return(NULL)
  }
  
  # filter to age group
  data <- data %>%
    filter(Treatment %in% Treatment)
  
  
  # if no remaining data, return NULL
  if (nrow(data) == 0) {
    
    return(NULL)
  }
  
  if (Treatment == "CTRL") {
    Treatment_title <- "Control"
  } else {
    Treatment_title <- stringr::str_glue("{str_remove(Treatment, 'Treatment')}")
  }
  
  
  ggplot(data, aes(x = WLR, y = Cell_Area)) +
    geom_jitter(aes(colour = Cell_Type),
      # fill = "grey",
      # outlier.colour = "red",
      # outlier.shape = 1
    ) +
    theme_minimal() +
    labs(
      x = "Cell Perimeter",
      y = "Cell Area",
      title = stringr::str_glue("eek - {plot_title_district}"),
      subtitle = Treatment_title
    )
  
}

## Trying new thing 9.2.22

# plot_subset <- function(data, variable, choices) {
# 
#   data %>%
#     filter((!!sym(variable)) %in% choices) %>%
#     select(c(!!sym(variable), mpg))
# 
# }


















