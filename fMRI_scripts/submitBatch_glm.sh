#!/bin/bash -l

# filename with subject ids
batch=$1

# for each subj id in batch, run the GLM if it hasn't been done before
cat $batch | while read line || [ -n "$line" ]; do \
    if [ ! -f ./output/glm004_subject${line}.nii.gz ] ; then
        echo "Subj $line is running..."
        qsub glm4.sh $line -P cd-narps
    else
        echo "GLM for participant ${line} already exists..."
    fi ; \
done