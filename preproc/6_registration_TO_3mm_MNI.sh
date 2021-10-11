#!/bin/bash 

read -p "Enter Subject Name: " subj
DATAPATH=/STUDYFOLDER
ses='ses-01'
fmri='taskname'  #OR RS for resting state
bet='fslbet'
VoxelSize="3"
GSPATH=/SCRIPTFOLDER

for subs in  `ls -d ${DATAPATH}/preproc/*$subj*`;do

	subject=$(basename $subs)

	if [ -e ${subs}/$ses/func/$fmri/FEAT.feat/${subject}_FEAT_detrend_filt_denoised.nii.gz ];then

		if [ -e ${subs}/$ses/func/$fmri/FEAT.feat/${subject}_FEAT_detrend_filt_denoised_${VoxelSize}mm.nii ];then

			echo "Denoised data from $subject has already registered to $VoxelSize mm MNI!"
		else
			#create and submit job to grid 

			FuncPath="${subs}/$ses/func/$fmri/FEAT.feat"
			FuncImage="${subject}_FEAT_detrend_filt_denoised" 
			AnatPath="${subs}/$ses/anat/$bet"
			AnatImage="${subject}"
			Preproc="${FuncPath}/${FuncImage}.nii.gz" # Preprocessed data image
			Registered="${FuncPath}/${FuncImage}_${VoxelSize}mm.nii.gz" # Registered image
			BET=${AnatPath}/${AnatImage}_$ses'_'*brain.nii.gz # Brain extracted anatomical image
			MNI=${GSPATH}/masks/MNIs/MNI152_T1_${VoxelSize}mm_brain.nii.gz # Standard MNI image
			mask=${GSPATH}/masks/3mm/avg152_T1_gray_mask_90_3mm_binary.nii	
			Preproc_to_BET="${FuncPath}/reg/${FuncImage}_preproc_to_BET.mat" # Lowres registration matrix
			BET_to_MNI="${FuncPath}/reg/${FuncImage}_BET_to_MNI.mat" # Highres registration matrix
			Preproc_to_MNI="${FuncPath}/reg/${FuncImage}_preproc_to_MNI.mat" # Final registration matrix

		## Run FLIRT commands

		# Create lowres registration matrix. Register preprocessed data to BET image and create preproc_to_BET matrix (A_to_B)
		echo "Create lowres registration matrix..."

		flirt -in ${Preproc} -ref ${BET} -omat ${Preproc_to_BET}
		# Create highres registration matrix. Register BET image to MNI space and create BET_to_MNI matrix (B_to_C)

		flirt -in ${BET} -ref ${MNI} -omat ${BET_to_MNI}
		# Create final registration matrix. Combine previously created matrices into preproc_to_MNI (A_to_C). This will be used for creating the registered images.
		## omat = name of concatenated matrices (A_to_C), 
		## concat = two matrices to be concatenated (B_to_C A_to_B)
		convert_xfm -omat ${Preproc_to_MNI} -concat ${BET_to_MNI} ${Preproc_to_BET}
		# Register preprocessed data to MNI space using MNI image and combined matrices
		flirt -in ${Preproc} -ref ${MNI} -out ${Registered} -applyxfm -init ${Preproc_to_MNI}
		gunzip ${Registered}
		echo "All registrations for $subject from $grp , $fmri , $ses is Done!"
		
		# Apply GM to registered to MNI data 
		fslmaths  $Registered -mas $mask $FuncPath/$subject'_'FEAT_detrend_filt_denoised_3mm_GMmasked.nii
		gunzip $FuncPath/$subject'_'FEAT_detrend_filt_denoised_3mm_GMmasked.nii
		echo $subject is GM Masked!

		fi
	else
		echo "There is no denoised data for $subject!"
	fi
done

