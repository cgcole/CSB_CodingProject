#!/bin/bash

#Change permissions to copy and rename files
chmod a+rwx ../flashdrive/Growth_Curves/*

#Searches the flashdrive for files that have test
test_files=$(find ../flashdrive/Growth_Curves/ -iname '*test*')

#For loop that takes each file from the flashdrive and changes the name copies it to the data folder 
for file in $test_files 
do 
  #The sed function here takes all the information past test (est to be case insensitve) to rename the file
  file_tag=$(echo "$file" | sed -ne 's/.*est//p')
  #In this case it does the same, but leaves out the .xlsx from the file name
  file_tag_without_xlsx=$(echo "$file" | sed -ne 's/.*est//;s/\..*$//p')
  #Copies the file to data folder without overrighting files already copied
  cp -n $file ../data/Nanobody_Slay_Test"$file_tag"
  #Creates a label csv that will be used to match to the data file in the R script based on a template
  cp -n ../input/template.csv ../input/Nanobody_Slay_Test"$file_tag_without_xlsx"_Labels.csv
done


echo "Now go to the input file directory and add labels for your tests"