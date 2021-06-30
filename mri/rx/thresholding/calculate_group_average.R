# This script calculates the group average of the ACF parameters
# D.Cos 12/2018

# user input
args = commandArgs(TRUE)
model_name = args[1]
model_dir = args[2]
output_dir = args[3]
sub_file = args[4]
sub_list = read.csv(sub_file, header = FALSE)

# load packages
library(tidyverse)

# load ACF param files and filter based on subject list
file_pattern = "ACFparameters_average.1D"
file_list = list.files(model_dir, pattern = file_pattern, recursive = TRUE)
file_sublist = grep(paste(sub_list$V1, collapse = "|"), file_list, value = TRUE)

task = data.frame()

for (file in file_sublist) {
    temp = tryCatch(read.csv(file.path(model_dir,file), header = FALSE) %>%
      mutate(file = file) %>%
      rownames_to_column() %>%
      spread(rowname, V1), error = function(e) NULL)
    task = rbind(task, temp)
    rm(temp)
}

# calculate average and write file
task %>%
  gather(key, value, 2:5) %>%
  group_by(key) %>%
  summarize(mean = mean(value, na.rm = TRUE)) %>%
  spread(key, mean) %>%
  select(-4) %>%
  write.table(file.path(output_dir, sprintf("%s_ACFparameters_group_average.txt", model_name)), sep = " ", col.names = FALSE, row.names = FALSE)
