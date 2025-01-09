#!/bin/bash

# convert DICOMs to BIDS format

subject=${1}

source "$CONFIG_FILE"

dcm2bids -d "$DICOM_DIR" -p "$subject" -s "$ses" -c "$CONFIG_BIDS" -o "$BIDS_DIR" --auto_extract_entities --force_dcm2bids
