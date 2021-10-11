#!/bin/bash 
read -p "Enter Subject Name: " subj
DATAPATH=/STUDYFOLDER
ses='ses-01'
fmri='taskname'  #OR RS for resting state
bet='fslbet'

fmri1=${fmri,,}
GSPATH=/SCRIPTFOLDER

RAWPATH=${DATAPATH}/preproc/
count=0


for subs in  `ls -d ${RAWPATH}/*$subj*`;do

	subject=$(basename $subs)

	if [ -d ${subs}/$ses/func/$fmri/FEAT.feat ] && [ -e ${subs}/$ses/func/$fmri/$subject'_'$ses'_'$fmri1.nii ];then

		cd ${subs}/$ses/func/$fmri/FEAT.feat/
		raw_file=$(ls -d ${subs}/$ses/func/$fmri/$subject'_'$ses'_'*.nii)
		tr=`fslinfo ${raw_file} | grep "pixdim4"  | head -n 1 |cut -c 10-20`
		##create subject specific background image
		if [ ! -e reg/highres2example_func.nii.gz ];then

			echo "Creating highres2example_func for $subject!"
			flirt -ref reg/example_func -in reg/highres -out reg/highres2example_func -applyxfm -init reg/highres2example_func.mat -interp trilinear

		fi

		if [ -e detrend_filt_func_data.ica/melodic_IC.nii.gz ];then
			icfile=`ls -d detrend_filt_func_data.ica/melodic_ICstats`
			icnum=`cat $icfile | wc -l `
			echo "melodic has been done for $fmri,$subject,number of ICs:$icnum !"
		else

			melodic -i ${subject}_FEAT_detrend_filt.nii.gz -o detrend_filt_func_data.ica  --dimest=mdl -v --nobet --bgthreshold=3 --tr=$tr --report --guireport=report.html -d 0 --mmthresh=0.5 --Ostats --bgimage=reg/highres2example_func.nii.gz

		fi
	else 
		echo "There is NO $fmri data for $subject !"
	fi
done


