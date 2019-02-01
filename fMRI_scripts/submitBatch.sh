#!/bin/bash -l

# filename with subject ids
batch=$1

# for each subj id in batch, run the smoothing
cat $batch | while read line || [ -n "$line" ]; do qsub smooth.sh $line -P cd-narps; done
