#!/bin/bash

# This script creates soft links to the BIDS-formatted T1w images

subjects=${1} # txt file of subject IDs, one ID per line

CONFIG_FILE=/scratch/USERNAME/brainageR/software/config
source $CONFIG_FILE

# Create an array of subject IDs
mapfile -t subjects <"$subjects"

for subject in "${subjects[@]}"; do
  # Generate the subject's folder in the destination
  mkdir -p "${DEST}"/"${subject}"

  # Create the symbolic link between the BIDS T1w and the brainageR T1 directory
  ln -s "$BIDS_DIR"/"$subject"/ses-"$ses"/anat/*T1w.nii.gz "${T1_DIR}"/"${subject}"

  # Unzip the T1w file
  unzip "${T1_DIR}"/"${subject}"/"$subject"_ses-"$ses"_T1w.nii.gz
done
