#!/bin/bash -l

# apply 3 mm smoothing to time series data for one subject
# conversion: FWHM = sigma * 2 * sqrt(2 * log(2))
# 3mm FWHM corresponds to a sigma of 1.274

# load modules within SCC
module load fsl
module list

ID=$1

for RUN in 01 02 03 04 ; do

  echo "Processing subject ${ID} run ${RUN}..."

  INPUT=../narps-data/derivatives/fmriprep/sub-${ID}/func/sub-${ID}_task-MGT_run-${RUN}_bold_space-MNI152NLin2009cAsym_preproc.nii.gz

  OUTPUT=../data_smoothed/sub-${ID}_run-${RUN}_sm3mm.nii.gz

  MASK=output/mask_union.nii.gz

  fslmaths $INPUT -mas $MASK -kernel gauss 1.274 -fmean $OUTPUT

done

echo "Done."

