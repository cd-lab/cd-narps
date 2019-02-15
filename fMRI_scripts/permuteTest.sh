#!/bin/bash -l

# load modules within SCC
module load fsl
module list

ID=$1
INPUT=${ID}/glm04_4D_sm4mm_mask85_${ID}.nii.gz
OUTPUT=${ID}/glm04_sm4mm_mask85_oneSamp_${ID}
MASK=mask_thresh_85.nii.gz

echo "Processing analysis ${ID}..."

# perform one-sample t-test
# -x indicates to output both correct and uncorrected maps
randomise -i $INPUT -o $OUTPUT -1 -S 10.69 -m $MASK -v 5 -d design102.mat -t design.con -f design.fts -x 


echo "Done."
