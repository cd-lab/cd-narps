#!/bin/bash -l

# load modules within SCC
module load fsl
module list

ID=$1 # dir name that contains the data and design files
THRESH=${2:-1.97} # threshold for clustermass (defaults to 1.97)

GROUP=$(echo $ID | cut -f 2 -d "_")
INPUT=${ID}/glm04_4D_sm4mm_mask85_${ID}.nii.gz
OUTPUT=${ID}/glm04_sm4mm_mask85_oneSamp_${ID}
MASK=mask_thresh_85.nii.gz
DESIGN=${ID}/design.mat
CONTRAST=${ID}/contrast.con

echo "Processing analysis ${ID}..."

# perform the permutation test
randomise -i $INPUT -o $OUTPUT -m $MASK -d $DESIGN -t $CONTRAST -x -R -N -P -C $THRESH -v 5


echo "Done."
