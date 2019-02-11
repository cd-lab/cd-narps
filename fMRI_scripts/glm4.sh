#!/bin/bash

# GLM 3 is for testing using only the base predictors. Prompted by the < full rank on sub 002

# load relevant modules
module load afni
module list

GLM_IDX=004
ID=$1

DATADIR=../data_smoothed
DATAHEAD=${DATADIR}/sub-${ID}
DATATAIL=sm3mm.nii.gz
MASK=output/mask_union.nii.gz
CONFOUNDS=../processed_confounds/sub-${ID}_AFNI_confounds_spread.tsv
FWD=../processed_confounds/sub-${ID}_AFNI_FWD.tsv 
ST_RT=../processed_eventfiles/sub-${ID}_RT_AFNI.tsv
ST_GAIN=../processed_eventfiles/sub-${ID}_gain_AFNI.tsv
ST_LOSS=../processed_eventfiles/sub-${ID}_loss_AFNI.tsv
ST_NORESP=../processed_eventfiles/sub-${ID}_noResponse_AFNI.tsv
OUTPUTTAG=output/glm${GLM_IDX}_subject${ID}
CHECK_NORESP="$(cat ${ST_NORESP} | grep -c '*')"

# if the subject had no no-responses, then avoid using noResponse as regressor
if [ $CHECK_NORESP -eq 4 ]; then 

  echo "Subject had no no-responses. Not using noResponse file..."

  3dDeconvolve -input \
    ${DATAHEAD}_run-01_${DATATAIL} \
    ${DATAHEAD}_run-02_${DATATAIL} \
    ${DATAHEAD}_run-03_${DATATAIL} \
    ${DATAHEAD}_run-04_${DATATAIL} \
    -mask $MASK -polort A \
    -ortvec $CONFOUNDS confounds \
    -num_stimts 3 \
    -stim_label 1 RT -stim_times_AM2 1 $ST_RT 'UBLOCK(4)' \
    -stim_label 2 gain -stim_times_AM1 2 $ST_GAIN 'UBLOCK(4)' \
    -stim_label 3 loss -stim_times_AM1 3 $ST_LOSS 'UBLOCK(4)' \
    -allzero_OK \
    -GOFORIT 4 \
    -censor $FWD \
    -bucket ${OUTPUTTAG}.nii.gz -tout -x1D $OUTPUTTAG

else 

  echo "No-responses available. Using them as regressors..."

  3dDeconvolve -input \
    ${DATAHEAD}_run-01_${DATATAIL} \
    ${DATAHEAD}_run-02_${DATATAIL} \
    ${DATAHEAD}_run-03_${DATATAIL} \
    ${DATAHEAD}_run-04_${DATATAIL} \
    -mask $MASK -polort A \
    -ortvec $CONFOUNDS confounds \
    -num_stimts 4 \
    -stim_label 1 RT -stim_times_AM2 1 $ST_RT 'UBLOCK(4)' \
    -stim_label 2 gain -stim_times_AM1 2 $ST_GAIN 'UBLOCK(4)' \
    -stim_label 3 loss -stim_times_AM1 3 $ST_LOSS 'UBLOCK(4)' \
    -stim_label 4 noResp -stim_times_IM 4 $ST_NORESP 'UBLOCK(4)' \
    -allzero_OK \
    -GOFORIT 4 \
    -censor $FWD \
    -bucket ${OUTPUTTAG}.nii.gz -tout -x1D $OUTPUTTAG

fi


