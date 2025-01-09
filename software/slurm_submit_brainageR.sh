#!/bin/bash

#SBATCH -t 1:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=8g

subjects=${1} # name of subject ID txt file

# Set up environment and change the username to your own
SOURCE_FILE=/scratch/USERNAME/brainageR/software/bashrc
CONFIG_FILE=/scratch/USERNAME/brainageR/software/config

source $SOURCE_FILE
source $CONFIG_FILE

# Create input, output, and log folders
cd "$SCRIPTS_DIR" || exit
mkdir -p "$T1_DIR"
mkdir -p "$OUT_DIR"
mkdir -p logs

# Helper function to return job id
function sb() {
	result="$(sbatch "$@")"

	if [[ "$result" =~ Submitted\ batch\ job\ ([0-9]+) ]]; then
		echo "${BASH_REMATCH[1]}"
	fi
}

# Make sure there are subjects
if [[ ${#subjects[@]} -eq 0 ]]; then
	echo "no subjects found in ${subjects}"
	exit 1
fi

# Create array of subject IDs
mapfile -t subjects <"$subjects"

# Calculate brain age for each subject
for subject in "${subjects[@]}"; do

	# Copy subject's raw T1 to the brainageR_T1 folder
	#mkdir -p $T1_DIR/$subject
	#cp -u $BIDS_DIR/anat/"$subject"_ses-"$ses"_T1w.nii.gz $T1_DIR/$subject $T1_DIR/$subject

	STEP1=$(sb "$OPTIONS" \
		--time=20:00 \
		--mem=24g \
		--cpus-per-task=4 \
		--job-name=brainageR \
		--export=ALL,CONFIG_FILE \
		--output="$SCRIPTS_DIR"/logs/"$subject"_brainage.log \
		--error="$SCRIPTS_DIR"/logs/"$subject"_brainage.error \
		"$SCRIPTS_DIR"/run_brainageR.sh "$subject" "$ses")
done

# Collate subject brain age files into single .csv file for export
#source $SCRIPTS_DIR/collate_brain_ages.sh $OUT_DIR $OUT_DIR/"$study"_ses-"$ses"_brain_age.csv
