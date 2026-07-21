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



echo ">> 1. Dereplicating sequences..."
qiime vsearch dereplicate-sequences \
  --i-sequences "$OUTPUT_ARTIFACT" \
  --o-dereplicated-table "${OUT_DIR}/derep-table.qza" \
  --o-dereplicated-sequences "${OUT_DIR}/derep-seqs.qza"

echo ">> 2. Clustering into 97% OTUs..."
qiime vsearch cluster-features-de-novo \
  --i-table "${OUT_DIR}/derep-table.qza" \
  --i-sequences "${OUT_DIR}/derep-seqs.qza" \
  --p-perc-identity 0.97 \
  --p-threads 4 \
  --o-clustered-table "${OUT_DIR}/table.qza" \
  --o-clustered-sequences "${OUT_DIR}/rep-seqs.qza"

echo ">> VSEARCH clustering completed. Outputs: table.qza, rep-seqs.qza"