#!/bin/bash

GLM_IDX=001
ID=001

DATADIR=../narps-data/derivatives/fmriprep/sub-${ID}/func
DATAHEAD=${DATADIR}/sub-${ID}_task-MGT
DATATAIL=bold_space-MNI152NLin2009cAsym_preproc.nii.gz
MASK=output/mask_union.nii.gz
CONFOUNDS=../processed_confounds/sub-${ID}_AFNI_confounds.tsv
ST_RT=../processed_eventfiles/sub-${ID}_RT_AFNI.tsv
ST_GAIN=../processed_eventfiles/sub-${ID}_gain_AFNI.tsv
ST_LOSS=../processed_eventfiles/sub-${ID}_loss_AFNI.tsv
ST_NORESP=../processed_eventfiles/sub-${ID}_noResponse_AFNI.tsv
OUTPUTTAG=output/glm${GLM_IDX}_subject${ID}

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
  -bucket ${OUTPUTTAG}.nii.gz -tout -x1D $OUTPUTTAG


