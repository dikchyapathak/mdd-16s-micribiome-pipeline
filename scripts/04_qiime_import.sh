#!/bin/bash

# Base directory for the project — UPDATE THIS to your local path, or export
# BASE_DIR as an environment variable before running.
BASE_DIR="${BASE_DIR:-/path/to/mdd-16s-microbiome-pipeline}"

# Define pathways
RAW_DIR="${BASE_DIR}/Raw_data"
QC_DIR="${BASE_DIR}/QC_data"
TRIMMED_DIR="${BASE_DIR}/Trimmed_data"
THREADS=12

OUT_DIR="${BASE_DIR}/Results"
OUTPUT_ARTIFACT="${OUT_DIR}/demux_F_seqs.qza"

mkdir -p "$QC_DIR" "$TRIMMED_DIR" "$OUT_DIR"

MANIFEST="${OUT_DIR}/manifest_forward.tsv"
echo ">> Creating manifest file: ${MANIFEST}"

# The header for single-end V2 manifests MUST be "absolute-filepath"
echo -e "sample-id\tabsolute-filepath" > "$MANIFEST"

# Finding the trimmed fastq files recursively in the TRIMMED_DIR and adding them to the manifest file
find "${TRIMMED_DIR}" -type f \( -name "*_1.trimmed.fastq.gz" -o -name "*_R1.trimmed.fastq.gz" -o -name "*_1.trimmed.fq.gz" -o -name "*_R1.trimmed.fq.gz" \) | while read -r R1; do
    # Extract sample name by stripping the suffix
    SAMPLE=$(basename "$R1" | sed -E 's/_(R|)1\.trimmed\.(fastq|fq)\.gz//')
    
    # Get the directory of R1 (kept from your original script, though unused here)
    SAMPLE_DIR=$(dirname "$R1")

    # Append to manifest file
    echo -e "${SAMPLE}\t${R1}" >> "$MANIFEST"
done

# Importing the manifest file into qiime2 as single-end
echo ">> Importing manifest file into QIIME2..."
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path "$MANIFEST" \
  --input-format SingleEndFastqManifestPhred33V2 \
  --output-path "$OUTPUT_ARTIFACT"
echo ">> QIIME2 import completed. Output artifact: ${OUTPUT_ARTIFACT}"

# Summarizing the imported data
echo ">> Summarizing the imported data..."
qiime demux summarize \
  --i-data "$OUTPUT_ARTIFACT" \
  --o-visualization "${OUT_DIR}/demux-F-summary.qzv"
echo ">> QIIME2 demux summary completed."