# CSB_CodingProject
Project for CSB 2020

Author: Cody Cole 

The purpose of this code is to transfer and anaylze bacterial growth curve data collected on a 96-well plate reader that measures the optical density of each individual well over a period of time. The wells contain bacteria, in this case E. coli W3110, with various plasmids that, for these experiments, display a nanobody or small peptide on the surface of the cell that may or may not be toxic. Once the assay has completed, the raw data from the plate reader can be exported in an excel spreadsheet for analysis. 

The code is meant to take files from a flashdrive that the excel files have been exported to, and process the data to generate plots for each assay. The flashdrive in this sceniaro is mimicked by the folder labeled flashdrive. All of the code is contained in the sandbox folder. file_movement_code.sh is the shell script that copies the data from the flashdrive and creates a file in the input folder based on each copied file that is used to input sample parameters for the data, since that isn't contained in the raw data. The R script that contains the commands that tidy the data and generate figures is code_script.R. code_markdown.Rmd is the combination of these two that describe the code in more detail.

When the R script has finished running plots for the data should be generated and saved in the plots folder under their test number that is specified by the file name of the raw data. 

In the flashdrive folder under Growth_Curves, I have raw data for 5 different tests that were run on the plate reader. The plots for the first few tests that were run don't look great, but that wasn't a result of the code. There were issues with in getting the 96-well plates set up correctly. It is pretty easy to tell that by the 5th test, I had worked out the kinks and produced results with much less variability. Turns out you have to tape the lid down on the 96-well plate otherwise the plate will shift in the plate reader and distort the absorbance reading. 

The markdown folder will run the code and everything, but won't display the plots. There are also some warnings that are triggered that I explain in the code. 