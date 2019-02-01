#!/bin/bash

# average the MNI-coregistered structural images for all subjects

fslmerge -t allStruct.nii.gz ../narps-data/derivatives/fmriprep/sub-*/anat/sub-*_T1w_space-MNI152NLin2009cAsym_preproc.nii.gz

fslmaths allStruct.nii.gz -Tmean output/T1_mean.nii.gz

rm allStruct.nii.gz



# create a group mask from the union of all single-run masks

fslmerge -t allMasks.nii.gz ../narps-data/derivatives/fmriprep/sub-*/func/sub-*_task-MGT_run-*_bold_space-MNI152NLin2009cAsym_brainmask.nii.gz

fslmaths allMasks.nii.gz -Tmax -bin output/mask_union.nii.gz
fslmaths allMasks.nii.gz -Tmin -bin output/mask_intersec.nii.gz

rm allMasks.nii.gz



# create a downsampled mean structural for the FSL underlay

flirt -in output/T1_mean.nii.gz -ref output/mask_union.nii.gz -applyxfm -out output/T1_mean_downsamp.nii.gz





