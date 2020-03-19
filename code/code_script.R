library(tidyverse)
library(readxl)


growth_curve_data <- read_excel("../data/Nanobody_Slay_Test_5.xlsx")
growth_curve_labels <- read_excel("../data/Nanobody_Slay_Test_5_Labels.xlsx")


growth_curve_data_final <- growth_curve_data %>%
  rename(Temperature = `Temperature(¡C)`) %>% 
  gather(Well, Absorbance, 3:98) %>% 
  separate(Time, c("Date", "Time"), sep = " ") %>%
  select(-Date) %>% 
  separate(Time, c("Hours", "Minutes"), extra = "drop", remove = FALSE) %>% 
  type_convert(cols(Hours = col_integer(),
                    Minutes = col_integer())) %>% 
  mutate(Hours = (Hours + (Minutes / 60))) %>% 
  select(-Minutes) %>% 
  left_join(growth_curve_labels)


growth_curve_summary <- growth_curve_data_final %>%
  group_by(Hours, Strain, Plasmid, Media, Condition1, Condition2) %>% 
  summarise(Mean_Absorbance = mean(Absorbance),
            SD = sd(Absorbance), 
            N = n(), 
            SEM = SD/sqrt(N),
            CI = SEM * qt(0.975, N-1)) %>% 
  group_by(Hours, Media, Condition1, Condition2) %>%
  mutate(Mean_Absorbance = Mean_Absorbance - Mean_Absorbance[Strain == "Blank"]) %>% 
  filter(Strain != "Blank")


x_upper <- max(growth_curve_summary$Hours)
y_upper <- max(growth_curve_data_final$Absorbance)
y_lower <- min(growth_curve_data_final$Absorbance)


if (y_upper < 2) {
  y_upper <- 2
} 
if (y_lower >= 0) {
  y_lower <- 0
} 



ggplot(data = growth_curve_summary) + 
  aes(x = Hours, y = Mean_Absorbance, color = Plasmid) +
  geom_point() +
  geom_line() +
  geom_errorbar(aes(ymin = (Mean_Absorbance - CI), 
                    ymax = (Mean_Absorbance + CI), width = .3)) +
  facet_grid(Condition1~Condition2) +
  ylab("Absorbance") + 
  theme_bw() +
  theme(legend.position = "bottom") +
  xlim(0, x_upper) +
  ylim(y_lower, y_upper) +
  expand_limits(x = )

  



  


