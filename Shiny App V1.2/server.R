#To begin, load all Libraries #################################################################

library("dplyr")
library("tidyverse")
library("ggplot2")
library("leaflet")
library("leaflet.extras")
library("plotly")
library("DT")
library("shiny")
library("ggiraph")
library("readr")
library("shinythemes")


#Next, choose a dataset to load ######################################################################


#Master <- read.csv("data/SLAS2_Master_110920.csv") #Main full dataset


Master <- read.csv("data/SLAS2_Master_110920Test.csv") #Smaller test dataset


#### Input to server #############################################################################################

function(input, output, session){
  
  
  #Load theme ####################################################################
  #To following lines of code define the aesthetics of the output graphs 
  
  lory_theme <- function() {
    theme(
      plot.background = element_rect(colour = "transparent", fill = "transparent"),
      # add border 1)
      strip.background = element_rect(fill = "transparent"),
      strip.text = element_text(family = "Arial", colour = "black", size = 8),
      strip.placement = "inside",
      panel.border = element_rect(colour = "grey25", fill = NA, linetype = 1),
      # color background 2)
      panel.background = element_rect(fill = "white"),
      # modify grid 3)
      panel.grid.major.x = element_line(colour = "grey25", linetype = 3, size = 0.15),
      panel.grid.minor.x = element_line(colour = "grey25", linetype = 3, size = 0.05),
      panel.grid.major.y =  element_line(colour = "grey25", linetype = 3, size = 0.15),
      panel.grid.minor.y = element_line(colour = "grey25", linetype = 3, size = 0.05),
      # modify text, axis and colour 4) and 5)
      
      axis.text = element_text(colour = "black", family = "Arial"),
      axis.title = element_text(colour = "black", family = "Arial"),
      axis.ticks = element_line(colour = "black"),
      # legend at the bottom 6)
      legend.position = "bottom",
      legend.title = element_text("idk")
    )
  }

  
  
#### tSNE plot #################################################################################################################### 
#The tSNE plot seen within the application is specified by the code within this section
  
  tSNEplot <- ggplot(Master, aes(tSNE_1, tSNE_2, data_id = tSNE_1, colour = factor <- get(input$select_col), res = 96)) +
    geom_point_interactive(size= 0.3,
                           shape = 21,
                           alpha = 0.3)+
    scale_x_continuous(limits = c(-35, 35),
                       breaks = c(0,-10,-20,10,20)) +
    scale_y_continuous(limits = c(-35, 35),
                       breaks = c(0,-10,-20,10,20)) +
    xlab("tSNE 1") +
    ylab("tSNE 2")+
    # scale_color_manual(values = c("orange","green","blue","red"))+
    # scale_color_brewer(palette = "Accent")+
    # scale_colour_gradient(low = "yellow", high = "red")+
    # scale_colour_gradient2(low = "red", mid = "orange", high = "green", midpoint = 0)+
    # facet_wrap(vars(Treatment, Cell_Type))+
    lory_theme() +
    labs(color = "input$select_col")
  

# Reactive elements ###########################################
 #The addition of these elements allows the tSNE plot to become interactive within the shiny application
  
  #Here, we specify the plot which we wish to make reactive, which is the tSNE plot 
  selected_tSNE_1 <- reactive({
    input$tSNEplot_selected
    })
  

  observe({
    selection <<-as.data.frame(Master[Master$tSNE_1 %in% selected_tSNE_1(),])
    })
  
  
  output$console3 <- renderPrint({
     input$tSNEplot_hovered
   })
  
  output$tSNEplot <- renderGirafe({
    tSNEplot <- girafe(code = print(tSNEplot),
                options = list(opts_selection(
                  type = "multiple", 
                  css = "fill:red;stroke:red;")))
    tSNEplot
    })
  
  output$dataplot <- renderGirafe({
    dataplot <- girafe(code = print(dataplot))
    dataplot
  })
  
  observeEvent(input$reset3, {
    session$sendCustomMessage(type = 'tSNEplot_set', 
                              message = character(0))
  })
  
  #This creates a datatable, and the input dataset is specified to originate from the Master and reflect the selected datapoints 
  #Extensions such as 'buttons' allows the used to subsequently save the generated datatable directly from the app, and the formats available to the user are specified within the options
  output$datatab3 <- renderDT(
    Master[Master$tSNE_1 %in% selected_tSNE_1(),],
    extensions = 'Buttons', 
    options = list(
      dom = 'Bfrtip',
      buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
      extensions = 'Responsive'))
  
  
  output$code <- renderPrint({ 
    summary(Master[Master$tSNE_1 %in% selected_tSNE_1(),],
            extensions = 'Buttons', 
            options = list(
              dom = 'Bfrtip',
              buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
              extensions = 'Responsive'))
  })

}
