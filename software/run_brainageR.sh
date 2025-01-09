#!/bin/bash

subject=${1}
ses=${2}

source /scratch/tbaran2_lab/brainageR/software/config

$SCRIPTS_DIR/brainageR -f $T1_DIR/$subject/"$subject"_ses-"$ses"_T1w.nii -o $OUT_DIR/"$subject"_ses-"$ses"_brain_age.csv


