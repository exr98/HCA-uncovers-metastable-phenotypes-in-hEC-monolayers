navbarPage(
  "Shiny V4.2",
  
  theme = shinythemes::shinytheme("flatly"),
  
  #First tab for introduction
  tabPanel("Welcome",
           #insert welcome messages 
           sidebarLayout(position = "left",
                         
                         sidebarPanel(
                           width = "4",
                           h3("Paper"),
                           p("You can read our paper titled 'High Content Analysis uncovers metastable phenotypes in human endothelial cell monolayers and key features across distinct populations' here:"
                           ),
                           p(a("https://journals.biologists.com/jcs/article-abstract/135/2/jcs259104/274116/High-content-image-analysis-to-study-phenotypic?redirectedFrom=fulltext")),
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
                           p(strong("-"),em("Plot tab"), "Within this tab you will find a data selector - use the options to select the data and press the run button to generate a plot. The filtered data will also be available as a downloadable datatable in the data tab. Depending on the type of variables plotted, statistics are automatically run and results can be viewed in the statistics tab")
                           #p(strong("-"),em("tSNE"), "allows exploration of our tSNE plot, where individual clusters can be selected for further analysis"),
                           #p(strong("-"),em("Spatial"), "shows spatial analysis of cells"),
                           #p(strong("-"),em("Pluri"), "is simply a general plot of all data available in our database with a selectable X and Y axis to allow free exploration")
                         ))
                         
           ),
  
  #Next tab for plot
  tabPanel("Plot",
           sidebarLayout(
             sidebarPanel(
               
               width = "3",
               
               #selector for x axis
               selectInput(
                 inputId = "select_x",
                 label = "Select x axis",
                 choices = c("Cell_Area",
                             "Cell_Type",
                             "Cell_Act_Cl",
                             "Cell_Perim",
                             "Cell_MaxL",
                             "WLR",
                             "Cell_Neighbour_N",
                             "tSNE_1",
                             "tSNE_2"),
                 selected = "Cell_Type"
               ),
               
               #selector for y axis
               selectInput(
                 inputId = "select_y",
                 label = "Select y axis",
                 choices = c("Cell_Area",
                             "Cell_Type",
                             "Cell_Act_Cl",
                             "Cell_Perim",
                             "Cell_MaxL",
                             "WLR",
                             "Cell_Neighbour_N",
                             "tSNE_1",
                             "tSNE_2"),
                 selected = "Cell_Area"
               ),

               
               selectInput(
                 inputId = "fact_var",
                 label = "Select factor variable",
                 choices = c("Cell_Area",
                               "Cell_Type",
                               "Cell_Act_Cl",
                               "Cell_Perim",
                               "Cell_MaxL",
                               "WLR",
                               "Cell_Neighbour_N"),
                             selected = "Cell_Type"
               ),
               
               #Selector for Image number 
               # sliderInput(
               #   inputId = "input_Img",
               #   label = "select image",
               #   min = 0, max = 1600, value = c(0, 1600),
               #   step = 1,
               #   animate = TRUE
               #   ),
               # 
               # selectizeInput(
               #   inputId = "input_Img",
               #   label = "select image",
               #   choices = c(0: 1600),
               #   selected = c(0: 1600),
               #   multiple = TRUE
               # ),
               
               
               #Selector for cell type
               checkboxGroupInput(
                 inputId = "input_Cell_Type",
                 label = "select Cell Type",
                 choices = c("HUVEC",
                             "HPMEC",
                             "HAoEC")
               ),
               
               
               
               #selector for treatment
               checkboxGroupInput(
                 inputId = "input_Treatment",
                 label = "selected treatment",
                 choices = c("Control" = "CTRL",
                             "VEGF"
                 )
               ),
               
               selectInput(
                 inputId = "plotchoice",
                 label = "Choose plot type",
                 choices = c("Box Plot",
                             "Scatter Plot",
                             "Violin Plot",
                             "Histogram"),
                 selected = "Box Plot"
               ),
               
               #selector for well
               selectizeInput(
                 inputId = "input_Well",
                 label = "select well",
                 choices = c("B02","B03","B04","B06","B07","B08",
                             "B002","B003","B004","B005","B006","B007","B008",
                             "D02","D03","D04","D06","D07","D08",
                             "D003","D004","D005","D006","D007","D008",
                             "G002","G003","G004",
                             "F02","F03","F04","F06","F07","F08",
                             "F002","F003","F004","F005","F006","F007"),
                 selected = c("B02","B03","B04","B06","B07","B08",
                              "B002","B003","B004","B005","B006","B007","B008",
                              "D02","D03","D04","D06","D07","D08",
                              "D003","D004","D005","D006","D007","D008",
                              "G002","G003","G004",
                              "F02","F03","F04","F06","F07","F08",
                              "F002","F003","F004","F005","F006","F007"),
                 multiple = TRUE
               ),
               
               actionButton("Button", "Update"),
               
               
               
             ),
             
             
             # First plot
             mainPanel(
               width = "6",
               tabsetPanel(
                 tabPanel("Plot",
                          plotOutput("my_plot")
                 ),
                 
                 tabPanel(
                   "Data",
                   DT::dataTableOutput("datatab")
                 ),
                 
                 tabPanel("Statistics",
                          fluidRow(
                            column(width = 4, strong(textOutput("num_var_1_title"))),
                            column(width = 4, strong(textOutput("num_var_2_title"))),
                            column(width = 4, strong(textOutput("fact_var_title"))),
                            ),
                          fluidRow(
                            column(width = 4, tableOutput("num_var_1_summary_table")),
                            column(width = 4, tableOutput("num_var_2_summary_table")),
                            column(width = 4, tableOutput("fact_var_summary_table")),
                          ),
                          fluidRow(
                            column(width = 4, strong("Combined Statistics"))
                          ),
                          fluidRow(
                            column(width = 4, tableOutput("combined_summary_table"))
                          )
                          )
               ))
           ))
)