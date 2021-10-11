#!/bin/bash

read -p "Enter Subject Name: " subj
DATAPATH=/STUDYFOLDER
ses='ses-01'
fmri='fischer'  #OR RS for resting state
bet='fslbet'

fmri1=${fmri,,}
GSPATH=/SCRIPTFOLDERS

RAWPATH=${DATAPATH}/preproc/
count=0

if [ ! -d ${DATAPATH}/designfiles/$study'_'$fmri'_'$ses ];then
	mkdir -p ${DATAPATH}/designfiles/$study'_'$fmri'_'$ses
fi
design_folder=${DATAPATH}/designfiles/$study'_'$fmri'_'$ses
for subs in  `ls -d ${RAWPATH}/$subj*`;do
	subject=$(basename $subs)

	if [ -d ${subs}/$ses/func/$fmri/FEAT.feat ] && [ -e ${subs}/$ses/func/$fmri/FEAT.feat/filtered_func_data.nii.gz ];then
		((count++))
		echo "$count,FEAT Directory for $subject already exists!"
	elif [ -d ${subs}/$ses/func/$fmri/ ] && [ -e ${subs}/$ses/func/$fmri/*task-$fmri1'_run-01_bold'.nii ];then

	###create a designfile for each subject and adjust name and paths
	cp ${GSPATH}/general_scripts/FSL_scripts/design_template_vox.fsf $design_folder/designfile_${subject}.fsf
	echo "VOX Template has been copied!"

	ntp=`fslinfo ${DATAPATH}/raw_data/$subject/$ses/func/$subject'_'$ses'_'task-$fmri1'_'${run}'_bold'.nii | grep "dim4"  | head -n 1 |cut -c 7-20`
	tr=`fslinfo ${DATAPATH}/raw_data/$subject/$ses/func/$subject'_'$ses'_'task-$fmri1'_'${run}'_bold'.nii | grep "pixdim4"  | head -n 1 |cut -c 10-20`
	### Adjust paths with IDs, parameters and standard image in each designfile

	sed 's/subjID/'$subject'/g' -i $design_folder/designfile_${subject}.fsf
	sed 's/session/'$ses'/g' -i $design_folder/designfile_${subject}.fsf

	sed 's/ntp/'$ntp'/g' -i $design_folder/designfile_${subject}.fsf
	sed 's/fmridir/'$fmri'/g' -i $design_folder/designfile_${subject}.fsf
	sed 's/fmrif/'$fmri1'/g' -i $design_folder/designfile_${subject}.fsf
	sed 's/reptime/'$tr'/g' -i $design_folder/designfile_${subject}.fsf

	sed 's/t1ses/'$t1ses'/g' -i $design_folder/designfile_${subject}.fsf
	sed 's/getbrain/'$bet'/g' -i $design_folder/designfile_${subject}.fsf
	###Start FEAT
	cd  $subs/$ses/func/$fmri/

	echo "START RUNING FEAT FOR $fmri of $subject ..."
	feat $design_folder/designfile_${subject}.fsf
	echo "FEAT IS DONE FOR $fmri of $subject."

	else
	echo "There is no $fmri1 data for $subject!"
	fi
done
