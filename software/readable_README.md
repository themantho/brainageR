# A readable README for brainageR v2.0

# Update history
# Mia Anthony (MA), Feb 5 2024

This is a more readable README of the supplied README.md for setting up brainageR on a high-performance cluster (HPC).

These instructions assume you have the brainageR folder with the modified setup. The modifications simplify running the software and do not alter the brain age calculation in any way (i.e., only the instructions here will differ slightly from README.md). The setup has been tested and run on the HPC bluehive at University of Rochester.

Refer to README.md to embark on a scavenger hunt for details meant to reaassure reviewers (i.e., data, model training, citations).


### Folder structure
# ---------------------------------------------------------------------------------
/brainageR_output
	The goods. Individual subject brain age and aggregate brain age files here.

/brainageR_T1
 	Create symbolic links to subjects' raw (unprocessed) T1.nii (make sure they are unzipped) or copy the files here, with a separate folder for each subject (i.e., /brainageR_T1/sub-ID/sub-ID_ses-xx_T1w.nii). These should be .nii, not .nii.gz or another zip flavor. The folder will contain intermediate files.

/logs
	The oracle. When things go wrong, go here for log and error files.

/scripts_templates
	Script templates specified in README.md are here. If you're looking to create more work for yourself and you fancy wading into README.md, then these scripts are for you.

/subjectIDs
	Store subject ID files here. Create a new ID list for each dataset (e.g., subjects_STUDY).
	If you read nothing else but this, this should be a text file with one ID per line and no extra whitespace before/after each ID, e.g.,
	sub-001
	sub-002
	.
	.
	.
	sub-00n

	When using a single subject ID file, make sure to overwrite it, rather than append new IDs to the existing list. Verify no whitespace or extra lines after the last ID exist.

/templates
	Needed to calcuate brain age. These are not script templates. DO NOT TOUCH. DO NOT CHANGE.
# ---------------------------------------------------------------------------------


### Setup
# ---------------------------------------------------------------------------------
1a. Open terminal load the R module:
module load r


 install the RNifti, stringr, and kerrnlab packages in your home directory.

1b. Create a conda env named 'brainager'. The bashrc_fs file does not create a conda env; it only sets up the HPC env with the software modules and activates the conda env. You only need to do create the conda env ONCE by running the command:

	conda create -n brainager

# ---------------------------------------------------------------------------------
2. Update the config file for your project

	a. Replace USERNAME with your user or group name.
	b. Replace 'study' with the name of your precious (dataset).

HOUSEKEEPING NOTES:
- The project paths will auto-populate with the user-defined variables.
- Software paths are specified in .bashrc_fs.
- User-defined paths are specified in the config file.
# ---------------------------------------------------------------------------------
3. Create a text file of subject IDs, with (pay attention) one ID per line. Ideally, your dicoms will already be in BIDS format. If not, you need to convert to BIDS.

	### For BIDS data, change PATH_TO_BIDS and SCRIPTS_PATH_IN_CONFIG and run these commands:

	BIDS_PATH=/PATH_TO_BIDS
	SCRIPTS_PATH=/SCRIPTS_PATH_IN_CONFIG
	$(echo ls $BIDS_PATH) > $SCRIPTS_PATH/subjects

	### For dicoms not in BIDS format, change PATH_TO_DICOMS and SCRIPTS_PATH_IN_CONFIG and run these commands:

	DICOM_PATH=/PATH_TO_DICOMS
	SCRIPTS_PATH=/SCRIPTS_PATH_IN_CONFIG
	$(echo ls $DICOM_PATH) > subjects

### Helpful commands if subject IDs have extraneous characters/numbers

	# to remove a string pattern in the subject IDs, run the command:
	echo "$(sed -r 's/PATTERN//' subjects)" > $SCRIPTS_PATH/subjects

	# EXAMPLE: for subject IDs 001_S_100x, remove '001_S_' and return only '100x'
	echo "$(sed -r 's/001_S_//' subjects)" > $SCRIPTS_PATH/subjects

	# to remove string patterns in multiple locations in the IDs, run the command:
	echo "$(sed -r 's/PATTERN_ONE//;s/PATTERN_TWO//' subjects)" > $SCRIPTS_PATH/subjects

	# EXAMPLE: for subject IDs 001_S_100x_Tx, remove '001_S_' and '_Tx'
	# T[0-9] means remove all numbers after 'T'
	echo "$(sed -r 's/001_S_//;s/_T[0-9]//' subjects)" > $SCRIPTS_PATH/subjects
# ---------------------------------------------------------------------------------
4. Run batch script

The brain age is calculated in approx. 15-20 min for a subject when using --mem=24g (line 45). The script requests --time=20:00 (line 44) and --mem=24g (line 45). Increase --time (hr:min), if jobs are exceeding the time limit.

The input for slurm_submit_brainageR.sh is the subjects ID text file. Submit the batch script to slurm with the command:

	sbatch slurm_submit_brainageR.sh subjects
# ---------------------------------------------------------------------------------
5. Collate subject files into single csv

brainageR generates a .csv file for each subject. After the batch job has completed, you can collate all subject brain ages into a single .csv.

The batch script performs this step after looping over all subjects. You can also comment out that line, process all subjects, then run the following command separately in terminal - this does not require activating the conda env or submitting a job to slurm. The output file will include subject ID, brain age, and lower/upper confidence intervals.

	# define folder paths for SCRIPTS_PATH and OUT_PATH
	SCRIPTS_PATH=/SCRIPTS_PATH
	OUT_PATH=/OUT_PATH

	# replace FILENAME with the desired filename (e.g., STUDY_ses-01_brain_age.csv).
	source $SCRIPTS_PATH/collate_brain_ages.sh $OUT_PATH $OUT_PATH/"$FILENAME"_brain_age.csv

6. Troubleshooting

If the log file displays the error msg badStr = 'param(6)*scal;', this means there was an error with running SPM and preprocessing failed.
