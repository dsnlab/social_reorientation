#!/bin/bash
. ~/.bashrc

# set paths and variables
# ------------------------------------------------------------------------------------------
# paths
subject_dir='/projects/dsnlab/SFIC_Self3/subjects' # subjects directory
model_dir='/projects/dsnlab/SFIC_Self3/analysis/rx/LME' #rx model directory
con_dir='/projects/dsnlab/SFIC_Self3/analysis/rx/LME_FX' #fx directory
parc_dir='/projects/dsnlab/SFIC_Self3/analysis/rx/parcellations/atlases' #parcellation atlas directory 
aparc_output='/projects/dsnlab/SFIC_Self3/analysis/rx/parcellations' #parcellation output directory
rx_output=(groupLevel) #sub-directory in $aparc_output
fx_output=(subjectLevel) #sub-directory in $aparc_output

# variables
parc=(craddock_all.nii.gz) #parcellation atlas file
parc_map=(31) #parcellation map number (if applicable)
aparc=(aligned_craddock_400) #aligned parcellation map name
aparc_num=$(seq 1 400) #parcellation numbers to extract from; use $(seq 1 N) where N is the total number of parcels to extract from all
runs=(t1 t2 t3)
rx_modelName=(age) #name of rx constrast for output files
rx_model=age_exclusions+tlrc #rx con file to extract from
rx_con=[10,12,14,16,18,20,22,24,26,28]
fx_con=(con_0001 con_0002 con_0003 con_0004) #fx con files to extract from

# subjects
cd $subject_dir
subj=$(ls -d s0*)

# ------------------------------------------------------------------------------------------
# align parcellation map to data
echo "aligning parcellation map"
if [ -f $parc_dir/${aparc}+tlrc.BRIK ]; then
	echo "aligned parcellation map already exists"
else 
3dAllineate -source $parc_dir/$parc[$parc_map] -master $model_dir/$rx_model -final NN -1Dparam_apply '1D: 12@0'\' -prefix $parc_dir/$aparc
fi


# loop through parcellations and extract from group-level rx_models
# echo "extracting from rx cons"
# for num in ${aparc_num[@]}; do
# 	echo $num
# 	3dmaskave -sigma -quiet -mrange $num $num -mask $parc_dir/${aparc}+tlrc $model_dir/$rx_model$rx_con > $aparc_output/$rx_output/${rx_modelName}_${num}.txt
# done


# loop through parcellations and extract from subject-level cons
echo "extracting from fx cons"
for sub in ${subj[@]}; do
	for run in ${runs[@]}; do
		for con in ${fx_con[@]}; do
			for num in ${aparc_num[@]}; do
				3dmaskave -sigma -quiet -mrange $num $num -mask $parc_dir/${aparc}+tlrc $con_dir/${sub}_${run}_${con}.nii > $aparc_output/$fx_output/${num}_${sub}_${run}_${con}.txt
			done
		done
	done
done
