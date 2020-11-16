navbarPage(
  
  "Shiny App with EC data", 
  
  theme = shinythemes::shinytheme("flatly"),
  
  
  fluidPage(
    sidebarPanel(
      
      selectInput("select_col",
                  label = "Select parameter visualisation",
                  choices = c("Cell_Type", 
                              "Experiment", 
                              "STB_Index", 
                              "Cell_Area", 
                              "WLR", 
                              "Nu_Clustering", 
                              "Cell_Cycle", 
                              "NOTCH_Quadr", 
                              "Cell_Act_Cl", 
                              "Cell_Neighbour_N"),
                  div(id = "step1", class = "well", "element1")),
      actionButton("reset3", label = "Reset selection")
      ),
    
    
  mainPanel(
    h4("tSNE Plot"),
    h4("Select cells: "),
    ggiraph::girafeOutput("tSNEplot"),
    h4("Selected Cells")
    ),

  
  mainPanel(
      DTOutput("datatab3"),
      verbatimTextOutput("code"),
      verbatimTextOutput("value"),
    )
  )
)



