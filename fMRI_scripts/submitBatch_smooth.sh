#!/bin/bash -l

# filename with subject ids
batch=$1

# for each subj id in batch, run the smoothing if the smoothed 4th run doesn't exist
# cat $batch | while read line || [ -n "$line" ]; do qsub smooth.sh $line -P cd-narps; done
cat $batch | while read line || [ -n "$line" ]; do \
    if [ ! -f ../data_smoothed/sub-${line}_run-04_sm3mm.nii.gz ] ; then
        echo "Subj $line is running..."
        qsub smooth.sh $line -P cd-narps
    else
        echo "Smoothed participant already exists..."
    fi ; \
done