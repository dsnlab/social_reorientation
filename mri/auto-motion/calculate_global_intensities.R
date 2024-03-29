# author: Dani Cosme
# email: dcosme@uoregon.edu
# version: 0.1
# date: 2017-03-03

# This script loads functional volumes, calculates the mean global intensity value,
# and returns a csv file 'study_globalIntensities.csv'
# 
# Inputs:
# * subjectDir = path to subject directory
# * functionalDir = path from subject's directory to to functional files
# * outputDir = path where study_globalIntensities.csv will be written
# * study = study name
# * subPattern = regular expression for subject IDs
# * prefix = SPM prefix appended to functional images; use "" to ignore
# * wavePattern = regular expression for wave names; use "" to specify all directories in $functionalDir
# * threshold = voxel intensity value used to truncate the distribution
# * final_output_csv = path and file name for 'study_globalIntensities.csv'
# * parallelize = use TRUE to parallelize, FALSE if not
# * leave_n_free_cores = number of cores to leave free
#
# Outputs:
# * study_globalIntensities.csv = CSV file with global intensity value for each image

#------------------------------------------------------
# load packages
#------------------------------------------------------
osuRepo = 'http://ftp.osuosl.org/pub/cran/'

if(!require(devtools)){
  install.packages('devtools',repos=osuRepo)
}
if(!require(RNifti)){
  devtools::install_github("jonclayden/RNifti")
}
require(RNifti)
if(!require(tidyverse)){
  install.packages('tidyverse',repos=osuRepo)
}
require(tidyverse)
if(!require(parallel)){
  install.packages('parallel',repos=osuRepo)
}
require(parallel)

#------------------------------------------------------
# define variables
# these variables are all you should need to change
# to run the script
#------------------------------------------------------

# paths
subjectDir = "/Volumes/psych-cog/dsnlab/SFIC_Self3/subjects" #"/Volumes/FP/research/dsnlab/Studies/FP/subjects" #"/Volumes/psych-cog/dsnlab/TDS/archive/subjects_G80/"
functionalDir = "ppc"
outputDir = "/Volumes/psych-cog/dsnlab/SFIC_Self3/notes/motion/auto-motion-output" #"/Volumes/psych-cog/dsnlab/auto-motion-output/" 

# variables
study = "SFIC" #"FP"
subPattern = "^s[0-9]{3}" #"^FP[0-9]{3}"
wavePattern = "^t[1-3]{1}"
prefix = "ob" #"o" 
threshold = 500 #5000
final_output_csv = file.path(outputDir,paste0(study,'_globalIntensities.csv'))
parallelize = TRUE
leave_n_free_cores = 1

#------------------------------------------------------
# calculate mean intensity for each functional image
#------------------------------------------------------

# get subjects list from subject directory
subjects = list.files(subjectDir, pattern = subPattern)

globint_for_sub <- function(sub, subjectDir, functionalDir, wavePattern, prefix, threshold){
  waves = list.files(paste0(subjectDir,'/',sub), pattern=wavePattern)

  for (wave in waves){
    # assign pattern based on prefix and wave
    filePattern = paste0('^',prefix,'_.*([0-9]{3}).nii')
    
    # generate file path
    path = file.path(subjectDir,sub,wave,functionalDir)
    file_list = list.files(path, pattern = filePattern)
    
    for (file in file_list){
      # if the merged dataset doesn't exist, create it
      if (!exists("dataset")){
        img = RNifti::readNifti(paste0(path,"/",file), internal = FALSE) #using `::` allows us to not load the package when parallelized
        dataset = tidyr::extract(data.frame(subjectID = sub,
                                            file = file,
                                            run = wave,
                                            volMean = mean(img[img > threshold], na.rm=TRUE),
                                            volSD = sd(img[img > threshold], na.rm=TRUE),
                                            volMin = min(img),
                                            volMax = max(img)),
                                 file, c("volume"), filePattern)
      }
      
      # if the merged dataset does exist, append to it
      else {
        img = RNifti::readNifti(paste0(path,"/",file), internal = FALSE)
        temp_dataset = tidyr::extract(data.frame(subjectID = sub,
                                                 file = file,
                                                 run = wave,
                                                 volMean = mean(img[img > threshold], na.rm=TRUE),
                                                 volSD = sd(img[img > threshold], na.rm=TRUE),
                                                 volMin = min(img),
                                                 volMax = max(img)),
                                      file, c("volume"), filePattern)
        dataset <- dplyr::bind_rows(dataset, temp_dataset)
        rm(temp_dataset)
      }
    }
  }
  if (!exists("dataset")){
    dataset = data.frame(subjectID = sub,
                         run = NA,
                         volMean = NA,
                         volSD = NA,
                         volume = NA)
  }
  return(dataset)
}

if(parallelize){
  time_it_took <- system.time({
    parallelCluster <- parallel::makeCluster(parallel::detectCores() - leave_n_free_cores)
    print(parallelCluster)
    datasets <- parallel::parLapply(parallelCluster, 
                                    subjects, 
                                    globint_for_sub, subjectDir, functionalDir, wavePattern, prefix, threshold)
    outdata <- bind_rows(datasets)
    # Shutdown cluster neatly
    cat("Shutting down cluster...")
    if(!is.null(parallelCluster)) {
      parallel::stopCluster(parallelCluster)
      parallelCluster <- c()
    }
  })
} else {
  time_it_took <- system.time({
    datasets <- lapply(subjects, 
                       globint_for_sub, subjectDir, functionalDir, wavePattern, prefix, threshold)
    outdata <- bind_rows(datasets)
  })
}
cat(paste0("For ", length(subjects), " participant IDs, the system logged this much time: \n"))
print(time_it_took)


#------------------------------------------------------
# write csv
#------------------------------------------------------
if (!dir.exists(dirname(final_output_csv))){
  dir.create(dirname(final_output_csv))
}
write.csv(outdata, final_output_csv, row.names = FALSE)
