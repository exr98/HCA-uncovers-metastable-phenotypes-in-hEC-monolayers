# HCA-uncovers-metastable-phenotypes-in-hEC-monolayers

This repository contains the scripts used in the paper ["High Content Analysis uncovers metastable phenotypes in human endothelial cell monolayers and key features across distinct populations"](incl. link to paper) for: 

- "ECPT" (Endothelial Cell Profiling Tool) contains 

- "Shiny App V1.2" contains the raw data .csv file and R scripts to reproduce the Shiny Application for interactive data selection 
 used to subset the data after tSNE clustering 
 
- "SLAS2_Stats_Notebook.Rmd" is an R notebook containing the scripts for reduction analysis and statistical analysis 

- "SLAS2 NotebookD1R3_4.Rmd" contains the R scripts for data visualisation


## ECPT
Endothelial Cell Profiling Tool (ECPT) expands on [previous work](https://journals.sagepub.com/doi/10.1177/2472555218820848) and provides a 
high content analysis platform to characterise single endothelial cells (EC) within an endothelial monolayer capturing context features, cell features and subcellular features including Inter-endothelial adherens junctions (IEJ). This unbiased approach allows to quantify EC diversity and feature variance.

Key improvements of the new workflow include:
1) The ability to phenotype widely heterogeneous EC without user input 
2) The reporting of single cell measurements  
3) The ability to perform correlative analysis between the different parameters (at single cell level)



### Requirements: 
1. Install [Fiji/ImageJ](https://imagej.net/Fiji/Downloads)
   - Insure [Trainable WEKA Segmentation](https://imagej.net/Trainable_Weka_Segmentation) is installed 
2. Install [CellProfiler](https://cellprofiler.org/releases)

All software required for this pipeline is open source and available for download via the above links. 


### Useage: 
For a detailed description and step-by-step walk through of carrying out analysis using ECPT, refer to the [supplementary methods section](Link to appendix).   




## Shiny App

### Requirements: 
1. Install [R](https://www.r-project.org/) and [R studio](https://rstudio.com/products/rstudio/download/)
   - Version 4.0.2. was used to develop this application and this version or above is required for useage 
2. Install the required R packages 
   - A download prompt should appear after loading the ShinyApp.Rproj in R Studio
     - Otherwise paste the code `<install.packages(c("dplyr", "tidyverse", "ggplot2", "leaflet", "leaflet.extras", "plotly", "DT", "shiny", "ggiraph", "js", "shinyjs", "maps", "car", "ggpmisc", "MASS", "scales", "viridis", "RSQLite", "htmltools", "shinyjs", "readr", "shinythemes"))>` into the console and hit enter, this should download all necessary packages. 
     ###### Note: The package installation process may take a few minutes. 

### Useage: 
- Open the 'Server.R' and 'UI.R' files stored within the R proj.
- In the Server.R file, load all libraries at the start of the R script (This can be done via Ctrl+Enter in windows or Shift+Enter for Mac or by selecting the code and hitting run in the top right hand corner) 
- Ensure the dataset has been downloaded and is in the data folder (this should happen automatically when the "Shiny App" file is downloaded), the Master raw data file is named "SLAS2_Master_110920" 
  - A 'test' dataset ("SLAS2_Master_110920Test") with a reduced number of data points can also be loaded by moving the position of the # in the section 'Load Data' like so: 
    - Orignal code to load full dataset: 
      - `<Master <- read.csv("data/SLAS2_Master_110920.csv") #Main full dataset>`               
      - `<#Master <- read.csv("data/SLAS2_Master_110920Test.csv") #Smaller test dataset>` 
  
    - To: 
      - `<#Master <- read.csv("data/SLAS2_Master_110920.csv") #Main full dataset>`                        
      - `<Master <- read.csv("data/SLAS2_Master_110920Test.csv") #Smaller test dataset>` 
     To load the test dataset. This dataset allows for an improved interactive experience and can be used to simply test the user experience of the Shiny App without the need to load the full dataset used for analysis
- To open the Shiny App from within R studio, click the 'Run App' button that appears at the top right hand corner of either the Server.R or UI.R file
  - This will prompt a pop out window with the Shiny App

- To close the Shiny App, simply close the pop up window or click the red stop button in the right hand corner of the console

###### Note:
- Code *cannot* run in R while the Shiny App is also running - before attempting to run code in R ensure the Shiny App window is closed or click the red stop button at the right hand corner of the console  
 

## Data Analysis 

The R scripts along with the raw data used to create all plots in the paper and carry out all statistical analysis can be found in the SLAS2 notebooks. 

### Requirements and useage: 

Before attempting to run the notebooks ensure: 
- [R](https://www.r-project.org/) and [R studio](https://rstudio.com/products/rstudio/download/) are installed
   - Version 4.0.2. was used at the time of writing and this version or above is required for useage 
- All required packages at the top of the script are installed and loaded 


## Authors:
Francois Chesnais(1), Juliette Le Caillec(1), Errin Roy(2), Davide Danovi(2), Lorenzo Veschini(1) 

(1) Vascular Cells Dynamics Lab, ACRS, Centre of Oral, Clinical and Translational Sciences, King’s College London. 

(2) Stem Cell Hotel, Centre for Stem Cells & Regenerative Medicine, King’s College London 


## For support please contact:
Lorenzo Veschini at lorenzo.1.veschini@kcl.ac.uk 


## Copy right and License Information: 

This software is licensed with GNU General Public License v3.0. Please see the attached [LICENSE](https://github.com/exr98/HCA-uncovers-metastable-phenotypes-in-hEC-monolayers/blob/main/LICENSE) file for details.
