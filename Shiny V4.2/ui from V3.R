navbarPage(
  "ECPT data visualisation and analysis",
  
  theme = shinythemes::shinytheme("sandstone"),
  
           tabPanel("Welcome",
                    sidebarLayout(position = "left",
                                  
                      sidebarPanel(
                        width = "3",
                        h3("Welcome"),
                        p("You can read out paper titled 'High Content Analysis uncovers metastable phenotypes in human endothelial cell monolayers and key features across distinct populations' here:"
                           ),
                        p(a("https://www.biorxiv.org/content/
                            10.1101/2020.11.17.362277v1")),
                      br(),
                      br(),
                      br(),
                      h3("Github"),
                      p("View all of our data and source code on our dedicated Github repository"),
                      p(a("https://github.com/exr98/HCA-uncovers-metastable-phenotypes-in-hEC-monolayers"))
                      ),
                      mainPanel(
                        width = "8",
                        h1("Welcome to the app"),
                        br(),
                        p("Endothelial Cell Profiling Tool (ECPT) expands on previous work and provides a high content analysis platform to characterise single endothelial cells (EC) within an endothelial monolayer capturing context features, cell features and subcellular features including Inter-endothelial adherens junctions (IEJ). This unbiased approach allows quantification of EC diversity and feature variance."),
                        br(),
                        br(),
                        h1("Features"),
                        br(),
                        p("Our Shiny application allows you to interactively explore our data without the need for RStudio"),
                        p(strong("-"),em("tSNE"), "allows exploration of our tSNE plot, where individual clusters can be selected for further analysis"),
                        p(strong("-"),em("Spatial"), "shows spatial analysis of cells"),
                        p(strong("-"),em("Pluri"), "is simply a general plot of all data available in our database with a selectable X and Y axis to allow free exploration")
                      )
                    )),
    
           tabPanel("tSNE",
                    sidebarLayout(
                      sidebarPanel(
                        width = "2",
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
                        tabsetPanel(
                          tabPanel("tSNE Plot",
                                   h4("tSNE Plot"),
                                   h4("Select cells: "),
                                   ggiraph::girafeOutput("tSNEplot"),
                                   h4("Selected Cells"),
                                   DT::dataTableOutput("datatab3")
                                   ), 
                          tabPanel("Summary",
                                   verbatimTextOutput("code"),
                                   verbatimTextOutput("value")
                                   ), 
                          tabPanel("Table")
                        )
                      ),
                    )),
  
           tabPanel("Spatial",
                    sidebarLayout(
                      sidebarPanel(
                        width = "2",
                        selectInput("select_CT",
                                    label = "Select Cell Type",
                                    choices = c("HAoEC",
                                                "HPMEC",
                                                "HUVEC"),
                                    selected = "HAoEC")
                      ),
                      mainPanel(
                        h4("Spatial Analysis Plot"),
                        plotOutput("Rubys"),
                        plotOutput("Rubys2"),
                        plotOutput("Rubys3")
                      )
                    )),
  
          tabPanel("Data Plot",
                   sidebarLayout(
                     sidebarPanel(
                       width = "2",
                       ## selection for PLURI X #########
                       
                       selectInput("select_X",
                                   label = "Select x axis",
                                   choices = c("Cell_Type",
                                               "Cell_Type",
                                               "Experiment",
                                               "STB_Index",
                                               "Cell_Area",
                                               "WLR",
                                               "Nu_Clustering",
                                               "Cell_Cycle",
                                               "NOTCH_Quadr",
                                               "Cell_Act_Cl",
                                               "Cell_Neighbour_N"),
                                   div(id = "step2", class = "well", "element2")),
                       #actionButton("reset3", label = "Reset selection")
                       
                       selectInput("select_Y",
                                   label = "Select y axis",
                                   choices = c("Tot_NCH",
                                               "Cell_Type",
                                               "Experiment",
                                               "STB_Index",
                                               "Cell_Area",
                                               "WLR",
                                               "Nu_Clustering",
                                               "Cell_Cycle",
                                               "NOTCH_Quadr",
                                               "Cell_Act_Cl",
                                               "Cell_Neighbour_N"),
                                   div(id = "step2", class = "well", "element2"))
                     ),
                     mainPanel(
                       h4("Data Plot"),
                       h4("Select Data: "),
                       ggiraph::girafeOutput("PLURI"),
                       h4("Selected Data"),
                       DT::dataTableOutput("datatab4")
                     ),
                  ))
)