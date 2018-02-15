#!/bin/bash -e

. $MODULESHOME/init/bash
module load python
module load matlab
module load freesurfer
module load SPM

#scriptDir=/projects/lliu/conmat/scripts/
scriptDir=/projects/sstojanovski/PNC_dti_conn/scripts/
cd ${scriptDir}

# enter project directory
projectName=PNC_dti_conn      #SPINS
projectDir=/scratch/sstojanovski/${projectName}/
projDirName=/scratch/sstojanovski/${projectName}

## Calling a scrip to pull all the connectivity matrices and put them into one folder
# and into a text file
parameters=( connectivity fa_mean length md_mean )
status=( control_arm_1 case_arm_2 )
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

#### NEED to edit pullMatrices.py
# Probably don't need all the conditions for renaming files

for stat in "${status[@]}"
do
  for param in "${parameters[@]}"
  do
    python pullMatrices.py ${projectName} ${param} ${stat}
  done
done

#-------------------------------------------------------------------------------
rm -r ${projectDir}/analysis

# making an analysis directory
mkdir ${projectDir}/analysis

#copy all files from all grouped folders into analysis folder
cp -r /scratch/sstojanovski/${projectName}/pipelines/grouped/fmri/. ${projectDir}/analysis
for param in "${parameters[@]}"
do
  cp -r /scratch/sstojanovski/${projectName}/pipelines/grouped/${param}/. ${projectDir}/analysis
done

#copy subject registered atlases into analysis folder
python pullAtlases.py ${projectName}

#-------------------------------------------------------------------------------

cd ${projectDir}/analysis

> listOfLists.m

for stat in "${status[@]}"
do
	echo fmri_${stat} = { $(<fmri_${stat}_fileNames.txt) } >> listOfLists.m
	for param in "${parameters[@]}"
	do
		echo ${param}_${stat} = { $(<${param}_${stat}_fileNames.txt) } >> listOfLists.m
	done
done

-------------------------------------------------------------------------------

# * write script that runs voxelCount.m and connectionWeight.m
# voxelCount(dtiList, fmriList) #the streamline list
# connectionWeight(dtiList, lengthList) #the streamline list

matlab -nodisplay -nosplash -r "addpath(genpath('/scratch/sstojanovski/conmat/scripts')); '/projects/lliu/conmat/scripts/weighting.m'; quit"

#-------------------------------------------------------------------------------

cd ${scriptDir}

weighted_parameters=( length_weighted connectivity_weighted )
python pullMatrices.py ${projectName} length_weighted control_arm_1
python pullMatrices.py ${projectName} connectivity_weighted control_arm_1

python pullMatrices.py ${projectName} length_weighted case_arm_2
python pullMatrices.py ${projectName} connectivity_weighted case_arm_2

for param in "${weighted_parameters[@]}"
do
  cp -r /scratch/lliu/${projectName}/pipelines/grouped/${param}/. ${projectDir}/analysis
done

cd ${projectDir}/analysis

for stat in "${status[@]}"
do
	for param in "${weighted_parameters[@]}"
	do
		echo ${param}_${stat} = { $(<${param}_${stat}_fileNames.txt) } >> listOfLists.m
	done
done

#-------------------------------------------------------------------------------

cp -r ${scriptDir}/. ${projectDir}/analysis
mkdir ${projectDir}/analysis/figures
mkdir ${projectDir}/analysis/tables

#-------------------------------------------------------------------------------

# Uses matlab to run getFigs.m and getTables.m in matlab
matlab -nodisplay -nosplash -r "addpath(genpath('/projects/lliu/conmat/scripts')); '/projects/lliu/conmat/scripts/getPlots.m'; quit"
matlab -nodisplay -nosplash -r "addpath(genpath('/projects/lliu/conmat/scripts')); '/projects/lliu/conmat/scripts/getTables.m'; quit"
cp -r /scratch/lliu/${projectName}/analysis/figures/. /scratch/lliu/${projectName}/analysis
matlab -nodisplay -nosplash -r "addpath(genpath('/projects/lliu/conmat/scripts')); '/projects/lliu/conmat/scripts/getFigs.m'; quit"

#-------------------------------------------------------------------------------
