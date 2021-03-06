library(tidyverse)
library(readxl)
library(stringi)


#Access files located in the data and plot directories 
data_files <- dir("../data", 
                  recursive=TRUE,full.names=TRUE)

plot_directory <- dir("../plots/",
                      recursive = FALSE,
                      full.names = FALSE)


#For loop that cleans and generates graphs for 
for (file in data_files) {
  
  #If statement to prevent reanalyzing already processed data
  #To rerun already analyzed data, delete files located in plots folder
  if (sum(str_detect(file, plot_directory)) == 0) {
    
    #Load in the data from files specified in for loop
    growth_curve_data <- read_excel(file)
    
    #Extracts test number from file to match to the label file that will be joined
    test_number <- stri_sub(file, 23, -6)
    growth_curve_labels <- read_csv(paste0("../input/Nanobody_Slay_", test_number,"_Labels.csv"))
    
    #This is an if statement to progress for loop in the event labels were not added to the label file
    if (length(unique(growth_curve_labels$Plasmid)) <= 1) next()
    
    
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
      #This unite function creates unique identifer for the samples that includes their replicates for overview_plot
      unite(Sample_id, 
            Strain, Plasmid, Media, Condition1, Condition2, 
            sep = "  ", 
            remove = FALSE,
            na.rm = TRUE) %>% 
      unite(Condition1,
            Media, Condition1, 
            sep = " + ", 
            remove = FALSE,
            na.rm = TRUE) %>% 
      unite(Strain_Plasmid,
            Strain, Plasmid, 
            sep = " + ", 
            remove = FALSE,
            na.rm = TRUE)
      
    
    #Summary of data for building the main_plot (This throws warning cause of NAs in Blank)
    growth_curve_summary <- growth_curve_data_final %>%
      group_by(Time, Hours, Temperature, Strain, Plasmid, Media, Condition1, Condition2, Strain_Plasmid) %>% 
      summarise(Mean_Turbidity = mean(Turbidity),
                SD = sd(Turbidity), 
                N = n(), 
                SEM = SD/sqrt(N),
                CI = SEM * qt(0.975, N-1)) %>% 
      group_by(Hours, Media, Condition1, Condition2) %>%
      mutate(Mean_Turbidity = Mean_Turbidity - Mean_Turbidity[Strain == "Blank"]) %>% 
      filter(Strain != "Blank") %>% 
      mutate(y_upper_limit = (Mean_Turbidity + CI)) %>% 
      mutate(y_lower_limit = (Mean_Turbidity - CI))
    
    
    #Set the limits used for ploting
    x_upper <- max(growth_curve_summary$Hours) + .1
    y_upper <- max(growth_curve_summary$y_upper_limit)
    y_lower <- min(growth_curve_summary$y_lower_limit)
    
    
    #Set preferred y limits for easy comparison of graphs between different tests
    if (y_upper < 1.75) {
      y_upper <- 1.75
    } 
    if (y_lower >= 0) {
      y_lower <- 0
    } 
    
    
    
    #This factors variables that are used for plotting and adjusts the order based 
    #the input of the user by using the unique function in levels
    growth_curve_summary$Strain_Plasmid <- factor(growth_curve_summary$Strain_Plasmid, 
                                           levels = c(unique(growth_curve_data_final$Strain_Plasmid)))
    growth_curve_summary$Condition1 <- factor(growth_curve_summary$Condition1, 
                                              levels = c(unique(growth_curve_data_final$Condition1)))
    growth_curve_summary$Condition2 <- factor(growth_curve_summary$Condition2, 
                                              levels = c(unique(growth_curve_data_final$Condition2)))
    growth_curve_data_final$Well <- factor(growth_curve_data_final$Well, 
                                           levels = c(unique(growth_curve_data_final$Well)))
    
    
    #Create the directory that the plots will go into dempending on the test number of the file
    dir.create(paste0("../plots/", test_number))
    
    
    #Generate overview plot for the whole 96-well plate
    ggplot(data = growth_curve_data_final) + 
      aes(x = Hours, y = Turbidity, color = Sample_id) +
      geom_line(size = 1) +
      facet_wrap(.~Well, ncol = 12) +
      ggtitle(paste0(test_number, " Overview Plot")) +
      ylab(expression("Turbidity (OD"[600]*")")) +
      theme(legend.position = "none") +
      scale_x_continuous(breaks = seq(0, x_upper, 5)) +
      scale_y_continuous(breaks = seq(0, y_upper, .75), 
                         limits = c(y_lower, y_upper)) +
      ggsave(paste0("../plots/", test_number,"/overview_plot.pdf"), 
             device = "pdf",
             width = 30,
             height = 18,
             units = "cm")
    
    
    #This if statement changes the main plot that is generated based on whether or not Media is different between the samples
    #In the event it is, it looks better when plotted differently 
    if (length(unique(growth_curve_summary$Media)) > 1) {
      
      #generates main_plot in  special case  
      ggplot(data = growth_curve_summary) + 
        aes(x = Hours, y = Mean_Turbidity, color = Strain_Plasmid) +
        geom_point() +
        geom_line() +
        geom_errorbar(aes(ymin = (Mean_Turbidity - CI), 
                          ymax = (Mean_Turbidity + CI), width = .18)) + 
        facet_grid(Condition2~Condition1) + 
        ylab(expression("Turbidity (OD"[600]*")")) + 
        theme_bw() +
        theme(legend.position = "bottom",
              legend.title = element_blank()) +
        ggtitle(paste0(test_number, " Main Plot")) +
        scale_y_continuous(expand = c(.02, 0), 
                           breaks = seq(0, y_upper, .25), 
                           limits = c(y_lower, y_upper)) + 
        scale_x_continuous(expand = c(.015, 0), 
                           breaks = seq(0, x_upper, 1), 
                           limits = c(0, x_upper)) +
        guides(color = guide_legend(nrow=3,byrow=TRUE)) +
        ggsave(paste0("../plots/", test_number,"/main_plot.pdf"), 
               device = "pdf",
               width = 30,
               height = 18,
               units = "cm")
      
    } else {
      
      #generates main_plot for rest of the data
      ggplot(data = growth_curve_summary) + 
        aes(x = Hours, y = Mean_Turbidity, color = Strain_Plasmid) +
        geom_point() +
        geom_line() +
        geom_errorbar(aes(ymin = (Mean_Turbidity - CI), 
                          ymax = (Mean_Turbidity + CI), width = .18)) + 
        facet_grid(Condition1~Condition2) + 
        ylab(expression("Turbidity (OD"[600]*")")) + 
        theme_bw() +
        theme(legend.position = "bottom",
              legend.title = element_blank()) +
        ggtitle(paste0(test_number, " Main Plot")) +
        scale_y_continuous(expand = c(.02, 0), 
                           breaks = seq(0, y_upper, .25), 
                           limits = c(y_lower, y_upper)) + 
        scale_x_continuous(expand = c(.015, 0), 
                           breaks = seq(0, x_upper, 1), 
                           limits = c(0, x_upper)) +
        guides(color = guide_legend(nrow=3,byrow=TRUE)) +
        ggsave(paste0("../plots/", test_number,"/main_plot.pdf"), 
               device = "pdf",
               width = 30,
               height = 18,
               units = "cm")
    } 
    
  }
}


