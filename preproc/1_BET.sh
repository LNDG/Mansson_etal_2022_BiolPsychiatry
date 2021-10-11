#!/bin/bash

## Brain Extraction (BET). Create brain extracted images using desired parameters.


read -p 'f threshold: ' f #The default is 0.5
read -p "Enter Subject Name: " subname

DATAPATH=/STUDYFOLDER
RAWPATH=$DATAPATH/preproc/
T1='T1w'
ses='ses-01'
for subs in  `ls -d ${RAWPATH}/*$subname*`;do
	subject=$(basename $subs)
	if [ -e ${subs}/$ses/anat/ ]; then 

		echo 'Start BET on' $subject	

		if [ ! -e ${subs}/$ses/anat/fslbet ]; then 
			mkdir -p ${subs}/$ses/anat/fslbet
		fi
		
		cp  ${subs}/$ses/anat/${subject}*_${T1}.nii  ${subs}/$ses/anat/fslbet/
		cd ${subs}/$ses/anat/fslbet

		bet  *_${T1}.nii ${subject}_${ses}_${T1}'_B'$f'_'bet -f $f -B

		echo  $subject 'is Done!'
	fi
done
