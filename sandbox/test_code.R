library(tidyverse)
library(readxl)


data_files <- dir("../data", 
                  recursive=TRUE,full.names=TRUE)

input_files <- dir("../input", 
                   recursive=TRUE,full.names=TRUE)

#Load in the data
growth_curve_data <- read_excel("../data/Nanobody_Slay_Test.xlsx")
growth_curve_labels <- read_csv("../input/Nanobody_Slay_Test_Labels.csv")


#In the event a well or multiple wells were messed up during preparation they can be removed here by specifying the well in select()
#growth_curve_data <- growth_curve_data %>% 
#  select(-A1)


#Clean up the data and join the labels that have to be input by the user
data_columns <- ncol(growth_curve_data)
growth_curve_data_final <- growth_curve_data %>%
  rename(Temperature = `Temperature(¡C)`) %>% 
  gather(Well, Turbidity, 3:data_columns) %>% 
  separate(Time, c("Date", "Time"), sep = " ") %>%
  select(-Date) %>% 
  separate(Time, c("Hours", "Minutes"), extra = "drop", remove = FALSE) %>% 
  type_convert(cols(Hours = col_integer(),
                    Minutes = col_integer())) %>% 
  mutate(Hours = (Hours + (Minutes / 60))) %>% 
  select(-Minutes) %>% 
  left_join(growth_curve_labels) %>% 
  unite(Sample_id, 
        Strain, Plasmid, Media, Condition1, Condition2, 
        sep = "  ", 
        remove = FALSE,
        na.rm = TRUE)  


#summary of data for building the plot (This throws warning cause of NAs in Blank)
growth_curve_summary <- growth_curve_data_final %>%
  group_by(Time, Hours, Temperature, Strain, Plasmid, Media, Condition1, Condition2) %>% 
  summarise(Mean_Turbidity = mean(Turbidity),
            SD = sd(Turbidity), 
            N = n(), 
            SEM = SD/sqrt(N),
            CI = SEM * qt(0.975, N-1)) %>% 
  group_by(Hours, Media, Condition1, Condition2) %>%
  mutate(Mean_Turbidity = Mean_Turbidity - Mean_Turbidity[Strain == "Blank"]) %>% 
  filter(Strain != "Blank")


#Set the limits used for ploting
x_upper <- max(growth_curve_summary$Hours) + .1
y_upper <- max(growth_curve_data_final$Turbidity)
y_lower <- min(growth_curve_data_final$Turbidity)


#Set preferred y limits for easy comparison of graphs between different tests
if (y_upper < 1.75) {
  y_upper <- 1.75
} 
if (y_lower >= 0) {
  y_lower <- 0
} 


#This factors variables that are used for plotting and adjusts the order based the input of the user by using the unique function in levels
growth_curve_summary$Plasmid <- factor(growth_curve_summary$Plasmid, 
                                       levels = c(unique(growth_curve_data_final$Plasmid)))
growth_curve_summary$Condition1 <- factor(growth_curve_summary$Condition1, 
                                          levels = c(unique(growth_curve_data_final$Condition1)))
growth_curve_summary$Condition2 <- factor(growth_curve_summary$Condition2, 
                                          levels = c(unique(growth_curve_data_final$Condition2)))
growth_curve_data_final$Well <- factor(growth_curve_data_final$Well, 
                                       levels = c(unique(growth_curve_data_final$Well)))


#Overview Plot
ggplot(data = growth_curve_data_final) + 
  aes(x = Hours, y = Turbidity, color = Sample_id) +
  geom_line(size = 1) +
  facet_wrap(.~Well, ncol = 12) + 
  ylab(expression("Turbidity (OD"[600]*")")) +
  theme(legend.position = "none") +
  scale_x_continuous(breaks = seq(0, x_upper, 5)) +
  scale_y_continuous(breaks = seq(y_lower, y_upper, .75), 
                     limits = c(y_lower, y_upper)) +
  ggsave("../plots/test/overview_plot.eps", 
         device = "eps",
         width = 26,
         height = 14,
         units = "cm")



#main_plot  
ggplot(data = growth_curve_summary) + 
  aes(x = Hours, y = Mean_Turbidity, color = Plasmid) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = (Mean_Turbidity - CI), 
                    ymax = (Mean_Turbidity + CI), width = .18)) + 
  facet_grid(Condition1~Condition2) + 
  ylab(expression("Turbidity (OD"[600]*")")) + 
  theme_bw() +
  theme(legend.position = "bottom",
        legend.title = element_blank()) +
  scale_y_continuous(expand = c(.02, 0), 
                     breaks = seq(0, y_upper, .25), 
                     limits = c(y_lower, y_upper)) + 
  scale_x_continuous(expand = c(.015, 0), 
                     breaks = seq(0, x_upper, 1), 
                     limits = c(0, x_upper)) +
  guides(color = guide_legend(nrow=2,byrow=TRUE)) +
  ggsave("../plots/test/main_plot.eps", 
         device = "eps",
         width = 26,
         height = 14,
         units = "cm")

rmarkdown::render("code_script.R", "pdf_document")

