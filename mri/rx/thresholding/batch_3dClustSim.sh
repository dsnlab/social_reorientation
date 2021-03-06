
#!/bin/bash
#--------------------------------------------------------------
# This script runs 3dClustSim for each model using acf parameters 
# generated by calculate_group_average.R
#	
# D.Cos 2018.11.06
#--------------------------------------------------------------

# Set your study
STUDY=/projects/dsnlab/shared/SFIC_Self3

# Set shell script to execute
SHELL_SCRIPT=3dClustSim.sh

# FP the results files
RESULTS_INFIX=3dclustsim

# Set output dir and make it if it doesn't exist
OUTPUTDIR=${STUDY}/code/afni/rx/thresholding/output

if [ ! -d ${OUTPUTDIR} ]; then
	mkdir -p ${OUTPUTDIR}
fi

# Set model dir and specify RX models
FXMODELDIR=${STUDY}/subjects
RXMODELDIR=${STUDY}/analysis/rx/LME
MODELS=(puberty_exclusions_2019)

# Set subject list for subs included in the RX model
SUBLIST=puberty_subject_list.txt

# Set job parameters
cpuspertask=1
mempercpu=8G

# Create and execute batch job
for MODEL in ${MODELS[@]}; do
	 	sbatch --export ALL,MODEL=$MODEL,FXMODELDIR=$FXMODELDIR,RXMODELDIR=$RXMODELDIR,OUTPUTDIR=$OUTPUTDIR,SUBLIST=$SUBLIST \
		 	--job-name=${RESULTS_INFIX} \
		 	-o ${OUTPUTDIR}/${MODEL}_${RESULTS_INFIX}.log \
		 	--cpus-per-task=${cpuspertask} \
		 	--mem-per-cpu=${mempercpu} \
			--account=dsnlab \
			--partition=short \
		 	${SHELL_SCRIPT}
	 	sleep .25
done
