# brainageR: Running on a High-Performance Cluster

This repo gives an overview for running brainageR (https://github.com/james-cole/brainageR.git) on a high-performance cluster (HPC). Refer to the original README.md in the software folder for development details (i.e., model training, citations). The setup has been tested and run on the HPC Bluehive at University of Rochester.

The repo includes the following modifications:

1. Scripts for batch calculation of brain age. The scripts submit jobs more efficiently by submitting a single job array instead of generating a separate script to be run for each subject. The brain age calculation itself remains unchanged.

2. brainageR requires three PCA files (see the Installation section in the original README for details): pca_center.rds, pca_scale.rds, and pca_rotation.rds. Two of the three files (pca_center.rds and pca_scale.rds) are already included in the software directory and do not need to be downloaded. You will need to download pca_rotation.rds separately because it exceeds GitHub's file size limits. Download pca_rotation.rds from the brainageR v2.1 Releases [page](https://github.com/james-cole/brainageR/releases), [Zenodo](https://doi.org/10.5281/zenodo.3463212) or [OSF](https://osf.io/azwmg/) and add it to the software directory so that the directory looks like this:

```
brainageR/
└── software/
    ├── pca_center.rds
    ├── pca_rotation.rds
    └── pca_scale.rds
    ...
```

3. Important: The modified scripts expect BIDS format. See Step 2 and https://unfmontreal.github.io/Dcm2Bids/3.2.0/ for more details on converting DICOMs to BIDS format.

## Folder structure

There are two subdirectories: software and dcm2bids.

### Software folder

All brainageR scripts and model data are stored in the software directory:

`/brainageR_output`

Individual subject brain age and aggregate brain age files will be here after running the calculation.

`/brainageR_T1`

Copy the raw (unprocessed) T1w nifti files or create symbolic links, with a separate folder for each subject (e.g., /brainageR_T1/sub-ID/sub-ID_ses-01_T1w.nii).

**Important**: The files should be .nii (unzipped nifti), not .nii.gz or another zip flavor. Intermediate files will also be stored here.

`/logs`

When things go wrong, look here for log and error files. If this folder does not exist initially, it will be created when you run the script.

`/scripts_templates`

Copies of the scripts referenced in the original README.md are here, as a backup.

`/subjectIDs`

Store subject ID files here. The subject ID file should be a text file with one ID per line and no extra whitespace before/after each ID. An example file is provided in this folder.

When using a single subject ID file, make sure to overwrite it, rather than append new IDs to the existing list. Verify no whitespace or extra lines exist after the last ID so that slurm does not submit a job for an "empty ID". When working with multiple subject ID files (e.g., multi-site data, testing a subject), it is recommended that you add a suffix to the 'subjects' file name (e.g., subjects_test, subjects_sitename), so that you can switch between different ID files when needed instead of repeatedly generating different ID files.

`/templates`

Templates used to calculate brain age. These are not script templates. DO NOT TOUCH. DO NOT CHANGE.

### dcm2bids folder

Example scripts for converting DICOMs to BIDS using the dcm2bids package are located in the dcm2bids folder. Note: These scripts were originally written for

`/bids_config`

Contains the BIDS configuration file. The config file should be created based on your MRI acquisition protocol parameters. By default it will deface the T1w image using pydeface. Note that this config is designed for dcm2bids >=3.0.0. dcm2bids>=3.0.0 is not compatible with config files made for v2.1.9 and below.

`/logs`

Log and error files for dcm2bids and pydeface will be stored here. dcm2bids and pydeface log subdirectories will be created by `submit_dcm2bids.sh`.

## Script overview

### Software folder

The brainageR package uses a combination of scripts to perform the following steps:

1. **Activate environment**: The bashrc file loads the HPC modules and software paths and activates the conda envrionment. The config file includes user-defined paths and variables. The project paths will auto-populate with the user-defined variables.

2. **DICOM-BIDS conversion**: The `submit_dcm2bids.sh` script iterates over an array of subject IDs and submits 'run_dcm2bids.sh' for each subject to convert the raw T1 images to BIDS. If your data is already in BIDS format, you can skip this step.

3. **Brain age calculation**: The `slurm_submit_brainageR.sh` script iterates over an array of subject IDs and submits `run_brainageR.sh` for each subject, allowing multiple subjects to run in parallel.

4. **Collate brain age calculations**: `collate_brain_ages.sh` collates the individual brain age calculations into a single csv file. The output csv and individual subject brain age csv files are stored in brainageR/software/brainageR_output/<study_name>.

### dcm2bids folder

1. **Activate environment**: `submit_dcm2bids.sh` calls the bashrc and config files in the software directory. Follow Step 2 to update the config file.

2. **DICOM-BIDS conversion**: `submit_dcm2bids.sh` submits a job array by calling `run_dcm2bids.sh` to convert the raw T1 images to BIDS for each subject. `run_dcm2bids.sh` uses the BIDS config file in /dcm2bids/bids_config to organize the DICOM files.

## Step 1: Setup environment

Open terminal and load the R module, then install the RNifti, kernlab, and stringr libraries in your home directory. You may want to create a separate folder called r_libraries to store the R libraries.

```bash
module load r

# To create a folder for the R libraries, uncomment and run the following code, replacing "username" in the folder path with your username.
# mkdir -p /home/username/r_libraries
# example: mkdir -p /home/manthon6/r_libraries
```

```r
# Install the R packages
install.packages("RNifti")
install.packages("kerrnlab")
install.packages("stringr")
```

The bashrc file does not create a conda env. The bashrc file only sets up the HPC env with the needed modules and activates the conda environment.

Create a conda environment named 'brainager' and install dcm2niix, dcm2bids, and pydeface via pip. You may need to upgrade pip first.

```python
# Create a conda environment
conda -n create brainager python=3.10

# Install latest version of dcm2niix and DICOM-to-BIDS converter
pip install -U dcm2niix dcm2bids pydeface
```

## Step 2. Update the config file

Several lines in the config file are user-specific (indicated by # CHANGE THIS in the file):

1. Line 15: Replace 'username' with your user or group name.
2. Line 30: Replace 'study' with the name of your dataset.
3. Line 31 (optional): If you only have one time point, then keep the default ses=01. If you have multiple time points, run the scripts with ses=01 first. For each additional time point, replace 'ses' with the BIDS session (i.e., timepoint) 0x, where x is the time point number (e.g., for baseline/T1: ses=01; T2: ses=02; T3: ses=03).
4. Lines 42-43: If you are converting DICOMs to BIDS, replace '/path/to/bids' and '/path/to/dicoms' with the paths of the BIDS and DICOM folders, otherwise comment out lines 42-44.

## Step 3. Convert DICOMs to BIDS

The batch scripts in this repo expect BIDS format. For dcm2bids usage, see https://unfmontreal.github.io/Dcm2Bids/3.2.0/. It is recommended that you deface the anatomical T1w image using pydeface (https://github.com/poldracklab/pydeface).

Several scripts are included in the dcm2bids directory to help you convert to BIDS. These files should NOT be used as-is and will require some editing based on your dataset:

1. Configure the BIDS config file based on the MRI acquisition protocol for your dataset. At a minimum, the config figure should convert the anat T1w image to BIDS.
2. Specify your username in `submit_dcm2bids.sh`.
3. Create the subject ID file for BIDS conversion.

### Create a subject ID file for BIDS conversion

Open a terminal window and change the current directory to the scripts folder, then load the config file and create a subject ID file with the following commands:

```bash
# Change current directory to the scripts folder, replacing 'username' with your own username.
cd /scratch/username/brainageR/software

# Load the config file - make sure you have updated the config file first!
source ./config

# Create the subject ID file
$(echo ls $DICOM_DIR) > $DCM_BIDS_DIR/subjects_dcm2bids
```

The subject ID file will be stored in /brainageR/dcm2bids.

## Step 4. Create a subject ID file for brainageR

Now we need to create a subject ID file for the brain age calculation. There is an example file in /software/subjectsIDs called 'subjects'. Either rename this file or delete it before creating your own subject ID file.

Open a terminal window and change the current directory to the scripts folder, then load the config file and create a subject ID file with the following commands:

```bash
# If you created the subject ID file for BIDS conversion, you can skip these first two commands, since they are the same.
cd /scratch/username/brainageR/software
source ./config

# Create the subject ID file
$(echo ls $BIDS_DIR) > $SCRIPTS_DIR/subjectIDs/subjects
```

The subject ID file will be stored in brainageR/software/subjectIDs.

## Step 5. Running the brainageR scripts

Before running the `slurm_submit_brainageR.sh` batch script, add the raw T1w nifti (.nii) images to the brainageR_t1 subdirectory. You can either copy the images directly to /brainageR_t1 or create symbolic links in the directory using `create_symlinks.sh`. The brainageR_t1 directory should look something like below. In this example, sub-001...sub-003 are example subject IDs and ses-01 refers to the baseline scan:

```
brainageR/
└── software/
    └── brainageR_t1/
        ├── sub-001_ses-01_T1w.nii
        ├── sub-002_ses-01_T1w.nii
        └── sub-003_ses-01_T1w.nii
    ...
```

**Important**: The T1w images must be unzipped. If the T1w images are .nii.gz, the brainageR script will not be able to locate the files.

Change the username in `slurm_submit_brainageR.sh`.

```bash
# Set up environment and change the username to your own
SOURCE_FILE=/scratch/USERNAME/brainageR/software/bashrc
CONFIG_FILE=/scratch/USERNAME/brainageR/software/config
```

Run `slurm_submit_brainageR.sh` with the following command in terminal, where 'subjects' is the input subject ID file:

```bash
sbatch slurm_submit_brainageR.sh subjects
```

The script requests the following resources to calculate brain age in approximately 15 min for each subject:
--time=20:00
--mem=24g
--cpus-per-task=4

If jobs are exceeding the time limit (you can check for jobs cancelled due to time limit exceeded in the log folder), increase --time (format min:sec) appropriately.

IMPORTANT: The "subjects" file input intentionally omits the ".txt" extension because the subject ID file is created without an explicit file type. This defaults to a text file, but you do not need to specify ".txt" when submitting the sbatch command. In other words, "subjects" and "subjects.txt" are not equivalent file names. If you encounter an error where the subject ID file cannot be located, this may be the source of the error, so be careful when naming files and specifying inputs.

## Step 5. Collate subject files into a single csv

brainageR generates a .csv file for each subject, which will be saved in /software/brainageR_output. After the batch job has completed, you can collate the individual csv files into a single summary .csv with `collate_brain_ages.sh`.

The batch script can perform this step after iterating over all subjects. You can also comment out the line (current set up), calculate the brain age for all subjects, then run the below commands in terminal. This does not require submitting a job to slurm, as the computational resources are minimal.

```bash
# Change current directory to the scripts folder, replacing 'username' with your own username.
cd /scratch/username/brainageR/software

# Load the config file
source ./config

# Define a file name or use info from the config file (as done here):
filename="$study"_ses-"$ses"_brain_age.csv

# Collate brain age into a csv file
source $SCRIPTS_DIR/collate_brain_ages.sh $OUT_DIR $OUT_DIR/$filename
```

The output file will include subject ID, brain age, and lower/upper confidence intervals. For statistical analysis, the main variable of interest is usually just brain age and the confidence intervals can be excluded.

If you cannot find the summary csv file, verify your OUT_DIR path!
