#!/bin/bash 

read -p "Enter Subject Name: " subj
DATAPATH=/STUDYFOLDER
ses='ses-01'
fmri='taskname'  #OR RS for resting state

fmri1=${fmri,,}

count=0
REJCOMPPATH=${DATAPATH}/report/IC_report/rejected_components/$fmri/$ses/
if [ ! -d ${REJCOMPPATH} ];then
	mkdir -p ${REJCOMPPATH} 
fi

for subs in  `ls -d ${DATAPATH}/preproc/*$subj*`;do
	subject=$(basename $subs)

	SUBPATH="${subs}/$ses/func/$fmri/FEAT.feat/"
	if [ -d ${SUBPATH} ];then
		rej_file=${REJCOMPPATH}/${subject}_$ses'_'$fmri1'_'rejected.txt
	fi

	if [ -d ${SUBPATH} ];then
		if [ -e ${SUBPATH}/${subject}_FEAT_detrend_filt_denoised.nii.gz ];then
			((count++))
			echo "$count,${subject} has been already denoised for $fmri!"
		else


			Input="${SUBPATH}${subject}_FEAT_detrend_filt.nii.gz"
			Output="${SUBPATH}${subject}_FEAT_detrend_filt_denoised.nii.gz"
			Melodic="${SUBPATH}detrend_filt_func_data.ica/melodic_mix"
		
			if [ -e $rej_file ];then
				Rejected=$(cat $rej_file)
				echo $subject , "Rejected Components: $Rejected"  
				fsl_regfilt -i ${Input} -o ${Output} -d ${Melodic} -f \"${Rejected}\"

				echo "Denoising for $subject is Done!"  
			else
				echo "There is NO rejected components for $fmri data for $subject !"
			fi
		fi
	else 
		echo "There is NO $fmri data for $subject !"
	fi
done


