#!/bin/bash -l


# load modules within SCC
module load fsl
module list

ID=$1


echo "Processing analysis ${ID}... "

INPUT=${ID}/glm04_4D_sm4mm_mask85_${ID}.nii.gz

OUTPUT=${ID}/glm04_oneSamp_${ID}.nii.gz


echo $INPUT
echo $OUTPUT

#perform one-sample t-test
# -x indicates to output both correct and uncorrected maps
randomise -i $INPUT -o $OUTPUT -x -1


echo "Done."
