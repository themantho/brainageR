# brainageR: Running on a High-Performance Cluster

This README is a modified version of the original README.md for running brainageR (https://github.com/james-cole/brainageR.git) on a high-performance cluster (HPC). Refer to the original README.md for development details (i.e., model training, citations).

These instructions assume you have downloaded the brainageR folder from this repo with the modified setup. The modifications include the following:

- Scripts for batch calculation of brain age. The scripts submit jobs more efficiently but do not alter the brain age calculation. The setup has been tested and run on the HPC Bluehive at University of Rochester.
- pca_center.rds, pca_rotation.rds, and pca_scale.rds files are included in this repo and do not need to be added (as per the installation instructions in the original README). If you have trouble downloading the PCA files from this repo, you can download them from the brainageR v2.1 Releases [page](https://github.com/james-cole/brainageR/releases), [Zenodo](https://doi.org/10.5281/zenodo.3463212) or [OSF](https://osf.io/azwmg/). Download all three files and add them to the brainager/software subdirectory.

Note 1: The installation steps in the original README (under Installation) have already been performed. You do not need to download additional files from the original brainageR git repo.

Note 2: The scripts expect BIDS format. See Step 2 and https://unfmontreal.github.io/Dcm2Bids/3.2.0/ for more details on converting DICOMs.

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

## Step 3. Update the config file

Several lines in the config file are user-specific (indicated by # CHANGE THIS VARIABLE in the config file):

1. Line 15: Replace 'username' with your user or group name.
2. Line 30: Replace 'study' with the name of your dataset.
3. Line 31 (optional): If you only have one time point, then keep the default ses=01. If you have multiple time points, run the scripts with ses=01 first. For each additional time point, replace 'ses' with the BIDS session (i.e., timepoint) 0x, where x is the time point number (e.g., for baseline/T1: ses=01; T2: ses=02; T3: ses=03).
4. Line 39: Replace 'your_BIDS_folder' in BIDS_DIR with the name of the folder containing the BIDS dataset.

Housekeeping notes:

- Software modules and paths are specified in .bashrc.
- User-defined paths are specified in the config file.
- The project paths will auto-populate with the user-defined variables.

## Step 4. Create a subject ID file

Now we need to create a subject ID file. There is an example file in the subjectsIDs subfolder called 'subjects', with one ID per line. Either rename this file or delete it before creating your own subject file.
Open a terminal window and change the current directory to the scripts folder, then load the config file and create a subject ID file with the following commands:

```
# Change current directory to the scripts folder, replacing 'username' with your own username.
cd /scratch/username/brainageR/software

# Load the config file - make sure you have completed Step 3 first!
source ./config

# Create the subject ID file
$(echo ls $BIDS_DIR) > $SCRIPTS_DIR/subjectIDs/subjects
```

The subject ID file will be stored in SCRIPTS_DIR/subjectIDs.

### Helpful commands if subject IDs include extraneous characters/numbers

To remove a string pattern in the subject IDs

```
echo "$(sed -r 's/PATTERN//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

Example: For subject IDs 001*S_100x, remove '001_S*' and return only '100x'

```
echo "$(sed -r 's/001*S*//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

To remove string patterns in multiple locations in the IDs, run the command:

```
# Define the string patterns
PATTERN_ONE="replace with a string pattern"
PATTERN_TWO="replace with another string pattern"

echo "$(sed -r 's/PATTERN_ONE//;s/PATTERN_TWO//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

Example: For subject IDs 001*S_100x_Tx, remove '001_S*' and '\_Tx'

```
# T[0-9] means remove all numbers after 'T'
echo "$(sed -r 's/001_S_//;s/_T[0-9]//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

## Step 4. Edit and run the scripts

Change the username in (lines 10-11) in slurm_submit_brainageR.sh.

```
# Set up environment and change the username to your own
SOURCE_FILE=/scratch/USERNAME/brainageR/software/bashrc
CONFIG_FILE=/scratch/USERNAME/brainageR/software/config
```

The main batch script is slurm_submit_brainageR.sh and takes the subjects ID file as its input with the following command in terminal:

```
sbatch slurm_submit_brainageR.sh subjects
```

The batch script loops over an array of subject IDs and submits a separate job to slurm for each subject, allowing you to run multiple subjects in parallel.

The script requests the following resources to calculate brain age in approx. 15 min for each subject:
--time=20:00
--mem=24g
--cpus-per-task=4

If jobs are exceeding the time limit (you can check for jobs cancelled due to time limit exceeded in the log folder), increase --time (format hr:min:sec) appropriately.

IMPORTANT: The "subjects" input intentionally omits the ".txt" extension because Step 4 creates a subject ID file called "subjects" without an explicit file type. This defaults to a text file, but you do not need to specify ".txt" in the sbatch input. In other words, "subjects" and "subjects.txt" are not equivalent file names. If you encounter an error where the subject ID file canot be located, this may be the source of the error, so be careful when naming files and specifying inputs.

## Step 5. Collate subject files into a single csv

brainageR generates a .csv file for each subject. After the batch job has completed, you can collate all subject brain ages into a single .csv.

The batch script can perform this step after looping over all subjects. You can also comment out that line (current set up), process all subjects, then run the below command separately in terminal. This does not require activating the conda env or submitting a job to slurm, as the computational resources are minimal.

```
# Change current directory to the scripts folder, replacing 'username' with your own username.
cd /scratch/username/brainageR/software

# Load the config file
source ./config

# Either define the filename based on info in the config file or specify a filename
filename="$study"_ses-"$ses"_brain_age.csv

# Collate brain age into a csv file
source $SCRIPTS_DIR/collate_brain_ages.sh $OUT_DIR $OUT_DIR/$filename
```

The output file will include subject ID, brain age, and lower/upper confidence intervals. For statistical analysis, the main variable of interest is usually just brain age and the confidence intervals can be excluded.

## Step 6. Troubleshooting

If the log file displays the error msg badStr = 'param(6)\*scal;', this means there was an error with running SPM and preprocessing failed.

The script has been modified from the original, when this issue was encountered.
