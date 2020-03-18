library(tidyverse)
library(readxl)

Growth_Curve_Data <- read_excel("../data/Nanobody_Slay_Test_5.xlsx")


Growth_Curve_Data <- Growth_Curve_Data %>%
  rename(Temperature = `Temperature(¡C)`) %>% 
  gather(Well, Absorbance, 3:98)  




  


