# brainageR v2.0

This README is an abbreviated and modified version of the full README.md for setting up brainageR on a high-performance cluster (HPC). Refer to README.md for development details (i.e., model training, citations).

These instructions assume you have the brainageR folder with the modified setup. The modifications run the software more efficiently and do not alter the brain age calculation (i.e., only the instructions here will differ slightly from README.md). The setup has been tested and run on the HPC Bluehive at University of Rochester.

Note 1: The installation steps in the original README (under Installation) have already been performed. You do not need to download additional files from the original brainageR git repo.

Note 2: The scripts expect BIDS format. See Step 2 and https://unfmontreal.github.io/Dcm2Bids/3.2.0/ for more details.

## Folder structure

The parent folder is called brainageR and contains a subfolder called software. Within /software are all subfolders and scripts (excluding your own data) needed to run the brain age calculation. Inside /software are the following subfolders:

/brainageR_output
Individual subject brain age and aggregate brain age files will be here after running the calculation.

/brainageR_T1
Create symbolic links to subjects' raw (unprocessed) T1.nii (make sure they are unzipped) or copy the files here, with a separate folder for each subject (i.e., /brainageR_T1/sub-ID/sub-ID_ses-xx_T1w.nii).
Important: The files should be .nii (unzipped nifti), not .nii.gz or another zip flavor. The folder will also contain intermediate files.

/logs
When things go wrong, look here for log and error files.

/scripts_templates
Script templates specified in README.md are here. To use a template, create a copy of the script and move into /software, then edit. If you want to create more work for yourself and run a separate script for each subject, then these scripts are for you.

/subjectIDs
If you read nothing else but this, this should be a text file with one ID per line and no extra whitespace before/after each ID, e.g.,
sub-001
sub-002
.
.
.
sub-00n

    When using a single subject ID file, make sure to overwrite it, rather than append new IDs to the existing list. Verify no whitespace or extra lines after the last ID exist.

/templates
Templates used to calculate brain age. These are not script templates. DO NOT TOUCH. DO NOT CHANGE.

## Step 1: Setup environment

Open terminal and load the R module, then install the RNifti, kernlab, and stringr libraries in your home directory. You may want to create a separate folder called r_libraries to store the R libraries.

```
module load r

# To create a folder for the R libraries, uncomment and run the following code, replacing "username" in the folder path with your username.
# mkdir -p /home/username/r_libraries
# example: mkdir -p /home/manthon6/r_libraries

# Install the R packages
install.packages("RNifti")
install.packages("kerrnlab")
install.packages("stringr")
```

Create a conda env named 'brainager'. The bashrc_fs file does not create a conda env. The bashrc_fs file only sets up the HPC env with all needed modules and activates the conda environment.

Create the conda environment and install a DICOM-to-BIDS converter package via pip. You may need to upgrade pip first.

```
conda -n create brainager

# Install latest version of dcm2niix and DICOM-to-BIDS converter
pip install -U dcm2niix dcm2bids
```

## Step 2. Convert DICOMs to BIDS

For dcm2bids usage, see https://unfmontreal.github.io/Dcm2Bids/3.2.0/
dcm2bids will convert DICOMs to BIDS, a neuroimaging file format standard. The batch scripts in this repo expect BIDS format.

## Step 3. Update the config file for your project

1. Replace USERNAME with your user or group name.
2. Replace 'study' with the name of your dataset.
3. Replace 'site' with the site name (e.g., for multi-site data) OR comment out.

Housekeeping Notes:

- The project paths will auto-populate with the user-defined variables.
- Software paths are specified in .bashrc_fs.
- User-defined paths are specified in the config file.

## Step 4. Create a text file of subject IDs

Next, create a text file with subject IDs, one ID per line. Change /path/to/bids/directory and /path/to/scripts/directory to your own paths and run the following commands to create a text file with subject IDs. The file will be stored in SCRIPTS_DIR.

```
BIDS_DIR=/path/to/bids/directory
SCRIPTS_DIR=/path/to/scripts/directory
$(echo ls $BIDS_DIR) > $SCRIPTS_DIR/subjects
```

### Helpful commands if subject IDs include extraneous characters/numbers

To remove a string pattern in the subject IDs

```
echo "$(sed -r 's/PATTERN//' subjects)" > $SCRIPTS_DIR/subjects
```

Example: For subject IDs 001*S_100x, remove '001_S*' and return only '100x'

```
echo "$(sed -r 's/001*S*//' subjects)" > $SCRIPTS_DIR/subjects
```

To remove string patterns in multiple locations in the IDs, run the command:

```
# Define the patterns
PATTERN_ONE="replace with a string pattern"
PATTERN_TWO="replace with another string pattern"

echo "$(sed -r 's/PATTERN_ONE//;s/PATTERN_TWO//' subjects)" > $SCRIPTS_DIR/subjects
```

Example: for subject IDs 001*S_100x_Tx, remove '001_S*' and '\_Tx'

```
# T[0-9] means remove all numbers after 'T'
echo "$(sed -r 's/001_S_//;s/_T[0-9]//' subjects)" > $SCRIPTS_DIR/subjects
```

## Step 4. Run batch script

The brain age is calculated in approx. 15-20 min for a subject when using --mem=24g (line 45). The script requests --time=20:00 (line 44) and --mem=24g (line 45). Increase --time (hr:min), if jobs are exceeding the time limit.

The input for slurm_submit_brainageR.sh is the subjects ID text file. Submit the batch script to slurm with the command:

```
sbatch slurm_submit_brainageR.sh subjects
```

Important: The "subjects" input intentionally omits the ".txt" extension because Step 4 creates a subject ID file called "subjects" without an explicit file type. This defaults to a text file, but you do not need to specify ".txt" in the sbatch input. In other words, "subjects" and "subjects.txt" are not equivalent file names. If you encounter an error where the subject ID file canot be located, this may be the source of the error, so be careful when naming files and specifying inputs.

## Step 5. Collate subject files into single csv

brainageR generates a .csv file for each subject. After the batch job has completed, you can collate all subject brain ages into a single .csv.

The batch script performs this step after looping over all subjects. You can also comment out that line, process all subjects, then run the following command separately in terminal - this does not require activating the conda env or submitting a job to slurm.

```
# Define folder paths for SCRIPTS_DIR and OUT_DIR
SCRIPTS_DIR=/SCRIPTS_DIR
OUT_DIR=/OUT_DIR

# Replace FILENAME with the desired filename (e.g., STUDY_ses-01_brain_age.csv).
source $SCRIPTS_DIR/collate_brain_ages.sh $OUT_DIR $OUT_DIR/"$FILENAME"_brain_age.csv
```

The output file will include subject ID, brain age, and lower/upper confidence intervals. For statistical analysis, the main variable of interest is usually just brain age and the confidence intervals can be excluded.

## Step 6. Troubleshooting

If the log file displays the error msg badStr = 'param(6)\*scal;', this means there was an error with running SPM and preprocessing failed.

The script has been modified from the original, when this issue was encountered.
