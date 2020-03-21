#!/bin/bash


#Change permissions to copy and rename files
chmod a+rwx ../flashdrive/Growth_Curves/*


#Searches the flashdrive for files that have test
test_files=$(find ../flashdrive/Growth_Curves/ -iname '*test*')


for file in $test_files 
do 
  file_tag=$(echo "$file" | sed -ne 's/.*est//p')
  file_tag_without_xlsx=$(echo "$file" | sed -ne 's/.*est//;s/\..*$//p')
  cp -n $file ../data/Nanobody_Slay_Test"$file_tag"
  cp -n ../input/template.csv ../input/Nanobody_Slay_Test"$file_tag_without_xlsx"_Labels.csv
done


echo "Now go to the input file directory and add labels for your tests"