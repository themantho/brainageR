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

/brainageR_output

Individual subject brain age and aggregate brain age files will be here after running the calculation.

/brainageR_T1

Create symbolic links to subjects' raw (unprocessed) T1.nii (make sure they are unzipped) or copy the files here, with a separate folder for each subject (e.g., /brainageR_T1/sub-ID/sub-ID_ses-01_T1w.nii).

Important:
The files should be .nii (unzipped nifti), not .nii.gz or another zip flavor. Intermediate files will also be stored here.

/logs

When things go wrong, look here for log and error files. If this folder does not exist initially, it will be created when you run the script.

/scripts_templates

Original script templates referenced in the original README.md are here. To use a template, create a copy of the script and move into /software, then edit.

/subjectIDs

Store subject ID files here. The subject ID file should be a text file with one ID per line and no extra whitespace before/after each ID, e.g.,
sub-001
sub-002
.
.
sub-00n

When using a single subject ID file, make sure to overwrite it, rather than append new IDs to the existing list. Verify no whitespace or extra lines exist after the last ID so that slurm does not submit a job for an "empty ID".

/templates

Templates used to calculate brain age. These are not script templates. DO NOT TOUCH. DO NOT CHANGE.

### dcm2bids folder

Scripts for converting DICOMs to BIDS using the dcm2bids package are located in the dcm2bids folder.

/bids_config

Contains the BIDS configuration file. The config file should be created based on your MRI acquisition protocol parameters. By default it will deface the T1w image using pydeface. Note that this config is designed for dcm2bids >=3.0.0. dcm2bids>=3.0.0 is not compatible with config files made for v2.1.9 and below.

/logs

Log and error files for dcm2bids and pydeface will be stored here. Log subdirectories will be created by 'submit_dcm2bids.sh', if they do not exist.

## Script overview

The brainageR package uses a combination of scripts to perform the following steps:

1. **Activate environment**: The `bashrc` file loads the HPC modules and software paths and activates the conda envrionment. The 'config' file includes user-defined paths and variables. The project paths will auto-populate with the user-defined variables.

2. **DICOM-BIDS conversion**: The `submit_dcm2bids.sh` script submits a job array by calling 'run_dcm2bids.sh' to convert the raw T1 images to BIDS for each subject. You can skip this step, if your data is already in BIDS format.

3. **Brain age calculation**: The 'slurm_submit_brainageR.sh' script submits a job array by calling 'run_brainageR.sh' to calculate brain age for each subject.

4. **Collate brain age calculations**: The 'collate_brain_ages.sh' script collates the individual brain age calculations into a single csv file. The output csv and individual subject brain age csv files are stored in brainageR/software/brainageR_output/<study_name>.

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

## Step 2. Convert DICOMs to BIDS

The batch scripts in this repo expect BIDS format.
For dcm2bids usage, see https://unfmontreal.github.io/Dcm2Bids/3.2.0/
dcm2bids will convert DICOMs to BIDS, a neuroimaging file format standard. It is recommended that you deface the anatomical T1w image using pydeface (https://github.com/poldracklab/pydeface).

Several scripts are included in the dcm2bids directory to help you convert to BIDS. These files should NOT be used as-is and will require some editing based on your dataset, particularly the BIDS config file, which should be created based on your MRI acquisition protocol.

## Step 3. Update the config file

Several lines in the config file are user-specific (indicated by # CHANGE THIS VARIABLE in the config file):

1. Line 15: Replace 'username' with your user or group name.
2. Line 30: Replace 'study' with the name of your dataset.
3. Line 31 (optional): If you only have one time point, then keep the default ses=01. If you have multiple time points, run the scripts with ses=01 first. For each additional time point, replace 'ses' with the BIDS session (i.e., timepoint) 0x, where x is the time point number (e.g., for baseline/T1: ses=01; T2: ses=02; T3: ses=03).
4. Line 39: Replace 'your_BIDS_folder' in BIDS_DIR with the name of the folder containing the BIDS dataset.

## Step 4. Create a subject ID file

Now we need to create a subject ID file. There is an example file in the subjectsIDs subfolder called 'subjects'. Either rename this file or delete it before creating your own subject ID file.

Open a terminal window and change the current directory to the scripts folder, then load the config file and create a subject ID file with the following commands:

```bash
# Change current directory to the scripts folder, replacing 'username' with your own username.
cd /scratch/username/brainageR/software

# Load the config file - make sure you have completed Step 3 first!
source ./config

# Create the subject ID file
$(echo ls $BIDS_DIR) > $SCRIPTS_DIR/subjectIDs/subjects
```

The subject ID file will be stored in SCRIPTS_DIR/subjectIDs.

### Converting DICOMs to BIDS: Helpful commands if subject IDs include extraneous characters/numbers

To remove a string pattern in the subject IDs

```bash
echo "$(sed -r 's/PATTERN//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

Example: For subject IDs 001*S_100x, remove '001_S*' and return only '100x'

```bash
echo "$(sed -r 's/001*S*//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

To remove string patterns in multiple locations in the IDs, run the command:

```bash
# Define the string patterns
PATTERN_ONE="replace with a string pattern"
PATTERN_TWO="replace with another string pattern"

echo "$(sed -r 's/PATTERN_ONE//;s/PATTERN_TWO//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

Example: For subject IDs 001*S_100x_Tx, remove '001_S*' and '\_Tx'

```bash
# T[0-9] means remove all numbers after 'T'
echo "$(sed -r 's/001_S_//;s/_T[0-9]//' subjects)" > $SCRIPTS_DIR/subjectIDs/subjects
```

## Step 4. Running the scripts

The main batch script is slurm_submit_brainageR.sh and takes the subjects ID file as its input with the following command in terminal:

```bash
sbatch slurm_submit_brainageR.sh subjects
```

slurm_submit_brainageR.sh loops over the array of subject IDs and submits run_brainageR.sh as a separate job to slurm for each subject, allowing you to run multiple subjects in parallel.

The script requests the following resources to calculate brain age in approximately 15 min for each subject:
--time=20:00
--mem=24g
--cpus-per-task=4

If jobs are exceeding the time limit (you can check for jobs cancelled due to time limit exceeded in the log folder), increase --time (format hr:min:sec) appropriately.

IMPORTANT: The "subjects" input intentionally omits the ".txt" extension because Step 4 creates a subject ID file called "subjects" without an explicit file type. This defaults to a text file, but you do not need to specify ".txt" in the sbatch input. In other words, "subjects" and "subjects.txt" are not equivalent file names. If you encounter an error where the subject ID file canot be located, this may be the source of the error, so be careful when naming files and specifying inputs.

Change the username in slurm_submit_brainageR.sh.

```bash
# Set up environment and change the username to your own
SOURCE_FILE=/scratch/USERNAME/brainageR/software/bashrc
CONFIG_FILE=/scratch/USERNAME/brainageR/software/config
```

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
