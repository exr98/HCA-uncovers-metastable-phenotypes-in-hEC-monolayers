# HCA-uncovers-metastable-phenotypes-in-hEC-monolayers

This repository contains the scripts used in the paper ["High content Image Analysis to study phenotypic heterogeneity in endothelial cell monolayers"](https://www.biorxiv.org/content/10.1101/2020.11.17.362277v4):

- **"FIJI_CP-Jan-22"** (Endothelial Cell Profiling Tool) contains
1) All macros (FIJI/ImageJ) for image pre processing and Weka segmentation.
2) The cell profiler pipeline used to carry out endothelial cell characterisation

- **"Shiny App V1.2"** contains the raw data .csv file and R scripts to reproduce the Shiny Application for interactive data selection
 used to subset the data after tSNE clustering

 To see the shiny application in action, go [here](https://errin.shinyapps.io/ECPT_Shiny_App/).

 **Within the "R-Analysis-Jan-22" folder:**

- **"ECPT_Data_Import.Rmd"** contains the R scripts used for data import and database cleaning

- **"ECPT_Stats.Rmd"** contains the R scripts used for statistical analysis and dimensionality reduction

- **"ECPT_Plots.Rmd"** contains the R scripts used for generation of plots and data visualisation

- **"ECPT_SAA.Rmd"** contains the scripts used for Spatial Autocorrelation Analysis  

- **"ECPT_DATA.rds"** contains a dataframe including all measures published in Chesnais et a., JCS 2022

&nbsp;


## ECPT
Endothelial Cell Profiling Tool (ECPT) expands on [previous work](https://journals.sagepub.com/doi/10.1177/2472555218820848) and provides a
high content analysis platform to characterise single endothelial cells (EC) within an endothelial monolayer capturing context features, cell features and subcellular features including Inter-endothelial adherens junctions (IEJ). This unbiased approach allows quantification of EC diversity and feature variance.

Key improvements of the new workflow include:
1) The ability to phenotype widely heterogeneous EC without user input
2) The reporting of single cell measurements  
3) The ability to perform correlative analysis between the different parameters (at single cell level)



### Requirements:
1. Install [Fiji/ImageJ](https://imagej.net/Fiji/Downloads)
   - Insure [Trainable WEKA Segmentation](https://imagej.net/Trainable_Weka_Segmentation) is installed
2. Install [CellProfiler](https://cellprofiler.org/releases)
   - Version 4.0.5. was used to develop this pipeline and this version or above is required for useage

All software required for this pipeline is open source and available for download via the above links.


### Useage:
For a detailed description and step-by-step walk through of carrying out analysis using ECPT, refer to [Appendix 1](https://www.biorxiv.org/content/10.1101/2020.11.17.362277v1.supplementary-material).   

&nbsp;



## Shiny App

The shiny app is available to view in browser from [here](https://errin.shinyapps.io/ECPT_Shiny_App/). The following sections outline how to view the code and deploy the shiny application from within R studio.

### Requirements:
1. Install [R](https://www.r-project.org/) and [R studio](https://rstudio.com/products/rstudio/download/)
   - Version 4.0.2. was used to develop this application and this version or above is required for useage
2. Install the required R packages
   - A download prompt should appear after loading the ShinyApp.Rproj in R Studio
     - Alternatively, paste the following code `<install.packages(c("dplyr", "tidyverse", "ggplot2", "leaflet", "leaflet.extras", "plotly", "DT", "shiny", "ggiraph", "js", "shinyjs", "maps", "car", "ggpmisc", "MASS", "scales", "viridis", "RSQLite", "htmltools", "shinyjs", "readr", "shinythemes"))>` into the console and hit enter to download all necessary packages.
     ###### Note: The package installation process may take a few minutes.

### Useage:
- Open the 'Server.R' and 'UI.R' files stored within the R proj.

- In the Server.R file, load all libraries at the start of the R script (This can be done via **Ctrl+Enter** in windows or **Cmd+Enter** for Mac or by selecting the code and hitting run in the top right hand corner)

##### Loading Data:
- Ensure the dataset has been downloaded and is in the data folder (this should happen automatically when the "Shiny App V1.2" file is downloaded), the Master data file is named "SLAS2_Master_110920" and needs to be unzipped before use due to the large file size
- A 'test' dataset ("SLAS2_Master_110920Test") with a reduced number of data points is also available and allows for an improved interactive experience to simply test the user experience of the Shiny App without the need to load the full dataset used for analysis. It can be loaded by moving the position of the # in the section 'Load Data' like so:
  - Orignal code to load full dataset:
      - `<Master <- read.csv("data/SLAS2_Master_110920.csv") #Main full dataset>`               
      - `<#Master <- read.csv("data/SLAS2_Master_110920Test.csv") #Smaller test dataset>`

   - To:
      - `<#Master <- read.csv("data/SLAS2_Master_110920.csv") #Main full dataset>`                        
      - `<Master <- read.csv("data/SLAS2_Master_110920Test.csv") #Smaller test dataset>`


##### Running/Closing the Shiny App:
- To open the Shiny App from within R studio, click the 'Run App' button that appears at the top right hand corner of either the Server.R or UI.R file
  - This will prompt a pop out window with the Shiny App
  - _**If an error is displayed, close the window and double check that all packages have been loaded and the .csv data file is in the data folder**_

- To close the Shiny App, simply close the pop up window or click the red stop button in the right hand corner of the console

###### Note: Code *cannot* run in R while the Shiny App is also running - before attempting to run code in R ensure the Shiny App window is closed or click the red stop button at the right hand corner of the console  

&nbsp;
&nbsp;

## Data Analysis

The R scripts along with the raw data used to create all plots and carry out all statistical analysis can be found in the "R-Analysis" folder.

### Requirements and useage:

Before attempting to run the notebooks ensure:
- [R](https://www.r-project.org/) and [R studio](https://rstudio.com/products/rstudio/download/) are installed
   - Version 4.0.2. was used at the time of writing and this version or above is required for useage
- All required packages at the top of the script are installed and loaded

&nbsp;
&nbsp;

## Authors:
Francois Chesnais(1), Juliette Le Caillec(1), Errin Roy(2), Davide Danovi(2), Lorenzo Veschini(1)

(1) Vascular Cells Dynamics Lab, ACRS, Centre of Oral, Clinical and Translational Sciences, King’s College London.

(2) Stem Cell Hotel, Centre for Stem Cells & Regenerative Medicine, King’s College London

&nbsp;

## For support please contact:
Lorenzo Veschini at lorenzo.1.veschini@kcl.ac.uk

For support using the respository and Shiny Application, contact Errin Roy at errin.roy@kcl.ac.uk

&nbsp;

## License Information:

This software is licensed with GNU General Public License v3.0. Please see the attached [LICENSE](https://github.com/exr98/HCA-uncovers-metastable-phenotypes-in-hEC-monolayers/blob/main/LICENSE) file for details.
