#!/bin/bash
#SBATCH -t 10:00
#SBATCH --mem-per-cpu=8gb

subjects=${1} # text file with subject IDs

# CHANGE LOCATION TO THE SOURCE AND CONFIG FILE
SOURCE_FILE=/scratch/USERNAME/brainageR/software/bashrc
CONFIG_FILE=/scratch/USERNAME/brainageR/software/config

source $SOURCE_FILE
source $CONFIG_FILE

# helper function to return job id
function sb() {
	result="$(sbatch "$@")"

	if [[ "$result" =~ Submitted\ batch\ job\ ([0-9]+) ]]; then
		echo "${BASH_REMATCH[1]}"
	fi
}

# get all subject names
mapfile -t subjects <"$subjects"

# create log files
mkdir -p "$LOG_DIR"/dcm2bids
mkdir -p "$LOG_DIR"/pydeface
mkdir -p "$BIDS_DIR"

for subject in "${subjects[@]}"; do

	# extract subject ID - EXAMPLE if your subject IDs have a prefix.
	#subject=${subject_folder#"$site_id"} # remove site ID prefix
	#subject=${subject%%-*}               # remove non-ID digits

	STEP1=$(sb "$OPTIONS" \
		--time=1:00:00 \
		--mem=64g \
		--cpus-per-task=4 \
		--job-name=dcm2bids \
		--export=ALL,CONFIG_FILE \
		--output="$LOG_DIR"/dcm2bids/dcm2bids_"$subject"_%j.log \
		--error="$LOG_DIR"/dcm2bids/dcm2bids_"$subject"_%j.error \
		"$SCRIPTS_DIR"/run_dcm2bids.sh "$subject")

done
