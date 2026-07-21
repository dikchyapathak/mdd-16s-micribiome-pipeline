#!/bin/bash

# Base directory for the project — UPDATE THIS to your local path, or export
# BASE_DIR as an environment variable before running.
BASE_DIR="${BASE_DIR:-/path/to/mdd-16s-microbiome-pipeline}"

# Define pathways
RAW_DIR="${BASE_DIR}/Raw_data"
QC_DIR="${BASE_DIR}/QC_data"
TRIMMED_DIR="${BASE_DIR}/Trimmed_data"
THREADS=12

# Create the output directory if it doesn't exist
mkdir -p "$QC_DIR" "$TRIMMED_DIR"

# Check if fastp is installed
if ! command -v fastp &> /dev/null; then
    echo "Error: fastp is not installed or not in your system PATH."
    exit 1
fi

echo "Starting Quality Control with fastp..."
echo "Input directory: $RAW_DIR"
echo "Output directory: $QC_DIR"
echo "Trimmed directory: $TRIMMED_DIR"
echo "-----------------------------------"

# Loop through all forward read files (_1.fastq.gz) in the raw directory
for R1 in "$RAW_DIR"/*_1.fastq.gz; do
    
    # Check if the file exists (handles the case where no files match the pattern)
    [ -e "$R1" ] || { echo "No FASTQ files found in $RAW_DIR. Exiting."; exit 1; }

    # Generate the corresponding reverse read filename (_2.fastq.gz)
    R2="${R1/_1.fastq.gz/_2.fastq.gz}"
    
    # Extract just the base sample name (e.g., SRR13307309) for naming outputs
    SAMPLE=$(basename "$R1" "_1.fastq.gz")
    
    echo "Processing sample: $SAMPLE"

    # Run fastp
    # -i / -I : Input forward and reverse reads
    # -o / -O : Output cleaned forward and reverse reads
    # -h / -j : Output HTML and JSON reports
    # -w      : Number of threads to use
    # --detect_adapter_for_pe : Automatically detect adapters for paired-end data
    
    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "${TRIMMED_DIR}/${SAMPLE}_1.trimmed.fastq.gz" \
        -O "${TRIMMED_DIR}/${SAMPLE}_2.trimmed.fastq.gz" \
        -h "${QC_DIR}/${SAMPLE}_fastp.html" \
        -j "${QC_DIR}/${SAMPLE}_fastp.json" \
        -w "$THREADS" \
        --detect_adapter_for_pe \
        2> "${QC_DIR}/${SAMPLE}_fastp.log" # Save the terminal output to a log file

done

echo "-----------------------------------"
echo "QC completed! All trimmed files and reports are saved in $QC_DIR"