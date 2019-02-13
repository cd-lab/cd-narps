#!/bin/bash -l

# apply 3 mm smoothing to time series data for one subject
# conversion: FWHM = sigma * 2 * sqrt(2 * log(2))
# 4mm FWHM corresponds to a sigma of 1.6986

# load modules within SCC
module load fsl
module list

ID=$1
THRESH=$2

SHORTID=${ID//_}


echo "Processing analysis ${ID}... "

INPUT=${ID}/glm04_4D_${SHORTID}.nii.gz

OUTPUT=${ID}/glm04_4D_sm4mm_${ID}.nii.gz

MASK=../individual_glm/mask_thresh_${THRESH}.nii.gz

echo $INPUT
echo $OUTPUT
echo $MASK

#fslmaths $INPUT -mas $MASK -kernel gauss 1.6986 -fmean $OUTPUT


echo "Done."
