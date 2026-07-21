#!/bin/bash

# --- Define Your Variables Here ---
# Base directory for the project — UPDATE THIS to your local path, or export
# BASE_DIR as an environment variable before running.
BASE_DIR="${BASE_DIR:-/path/to/mdd-16s-microbiome-pipeline}"

OUT_DIR="${BASE_DIR}/Results"
METADATA="${BASE_DIR}/metadata/metadata.tsv"
SAMPLING_DEPTH=35000 
THREADS=1

#dowloading the pre-trained classifier if it doesn't exist
# Downloading the classic scikit-learn 0.24.1 compatible classifier
CLASSIFIER_PATH="${OUT_DIR}/silva-138-99-515-806-nb-classifier.qza"
if [ ! -f "$CLASSIFIER_PATH" ]; then
    echo ">> Downloading the pre-trained classifier..."
    wget -O "$CLASSIFIER_PATH" "https://data.qiime2.org/2022.2/common/silva-138-99-515-806-nb-classifier.qza"
fi

# ==========================================
# 1. CHIMERA FILTERING & SUMMARY
# ==========================================
echo ">> Checking chimera filtering status..."
if [ ! -f "${OUT_DIR}/table-nonchimeric.qza" ]; then
    echo ">> Chimeras have not been filtered yet. Identifying chimeras..."
    qiime vsearch uchime-denovo \
      --i-table "${OUT_DIR}/table.qza" \
      --i-sequences "${OUT_DIR}/rep-seqs.qza" \
      --output-dir "${OUT_DIR}/uchime-out"

    echo ">> Filtering chimeras from the feature table..."
    qiime feature-table filter-features \
      --i-table "${OUT_DIR}/table.qza" \
      --m-metadata-file "${OUT_DIR}/uchime-out/chimeras.qza" \
      --p-exclude-ids \
      --o-filtered-table "${OUT_DIR}/table-nonchimeric.qza"

    echo ">> Filtering chimeras from the representative sequences..."
    qiime feature-table filter-seqs \
      --i-data "${OUT_DIR}/rep-seqs.qza" \
      --m-metadata-file "${OUT_DIR}/uchime-out/chimeras.qza" \
      --p-exclude-ids \
      --o-filtered-data "${OUT_DIR}/rep-seqs-nonchimeric.qza"
else
    echo ">> Chimeras have already been filtered. Skipping chimera filtering step."
fi

# Summarize the clean table so you can pick your SAMPLING_DEPTH
echo ">> Checking table summary status..."
if [ ! -f "${OUT_DIR}/table-nonchimeric.qzv" ]; then
    echo ">> Summarizing non-chimeric table..."
    qiime feature-table summarize \
      --i-table "${OUT_DIR}/table-nonchimeric.qza" \
      --o-visualization "${OUT_DIR}/table-nonchimeric.qzv" \
      --m-sample-metadata-file "$METADATA"
else
    echo ">> Non-chimeric table summary already exists. Skipping."
fi

# ==========================================
# 2. PHYLOGENETIC TREE
# ==========================================
echo ">> Checking phylogenetic tree status..."
if [ ! -f "${OUT_DIR}/rooted-tree.qza" ]; then
    echo ">> Building phylogenetic tree..."
    qiime phylogeny align-to-tree-mafft-fasttree \
      --i-sequences "${OUT_DIR}/rep-seqs-nonchimeric.qza" \
      --o-alignment "${OUT_DIR}/aligned-rep-seqs.qza" \
      --o-masked-alignment "${OUT_DIR}/masked-aligned-rep-seqs.qza" \
      --o-tree "${OUT_DIR}/unrooted-tree.qza" \
      --o-rooted-tree "${OUT_DIR}/rooted-tree.qza" \
      --p-n-threads "$THREADS"
else
    echo ">> Phylogenetic tree already exists. Skipping."
fi

# ==========================================
# 3. TAXONOMY ASSIGNMENT
# ==========================================
echo ">> Checking taxonomy assignment status..."
if [ ! -f "${OUT_DIR}/taxonomy.qza" ]; then
    echo ">> Assigning taxonomy..."
    qiime feature-classifier classify-sklearn \
      --i-classifier "$CLASSIFIER_PATH" \
      --i-reads "${OUT_DIR}/rep-seqs-nonchimeric.qza" \
      --o-classification "${OUT_DIR}/taxonomy.qza" \
      --p-n-jobs "$THREADS"
else
    echo ">> Taxonomy has already been assigned. Skipping."
fi

echo ">> Checking taxonomy barplots status..."
if [ ! -f "${OUT_DIR}/taxa-bar-plots.qzv" ]; then
    echo ">> Creating taxonomy barplots..."
    qiime taxa barplot \
      --i-table "${OUT_DIR}/table-nonchimeric.qza" \
      --i-taxonomy "${OUT_DIR}/taxonomy.qza" \
      --m-metadata-file "$METADATA" \
      --o-visualization "${OUT_DIR}/taxa-bar-plots.qzv"
else
    echo ">> Taxonomy barplots already exist. Skipping."
fi

# ==========================================
# 4. CORE DIVERSITY METRICS
# ==========================================
echo ">> Checking core diversity metrics status..."
# Checking for the output directory instead of a file
if [ ! -d "${OUT_DIR}/core-metrics-results" ]; then
    echo ">> Running core diversity metrics at sampling depth ${SAMPLING_DEPTH}..."
    qiime diversity core-metrics-phylogenetic \
      --i-phylogeny "${OUT_DIR}/rooted-tree.qza" \
      --i-table "${OUT_DIR}/table-nonchimeric.qza" \
      --p-sampling-depth "${SAMPLING_DEPTH}" \
      --m-metadata-file "$METADATA" \
      --output-dir "${OUT_DIR}/core-metrics-results"

else
    echo ">> Core diversity metrics directory already exists. Skipping."
fi

# ==========================================
# 5. BETA DIVERSITY SIGNIFICANCE (PERMANOVA)
# ==========================================
echo ">> Testing beta diversity significance for 'Phenotype'..."

# Unweighted UniFrac
if [ ! -f "${OUT_DIR}/core-metrics-results/unweighted-unifrac-treatment-significance.qzv" ]; then
    qiime diversity beta-group-significance \
      --i-distance-matrix "${OUT_DIR}/core-metrics-results/unweighted_unifrac_distance_matrix.qza" \
      --m-metadata-file "$METADATA" \
      --m-metadata-column "Phenotype" \
      --o-visualization "${OUT_DIR}/core-metrics-results/unweighted-unifrac-treatment-significance.qzv"
else
    echo ">> Unweighted UniFrac significance already tested. Skipping."
fi

# Weighted UniFrac
if [ ! -f "${OUT_DIR}/core-metrics-results/weighted-unifrac-treatment-significance.qzv" ]; then
    qiime diversity beta-group-significance \
      --i-distance-matrix "${OUT_DIR}/core-metrics-results/weighted_unifrac_distance_matrix.qza" \
      --m-metadata-file "$METADATA" \
      --m-metadata-column "Phenotype" \
      --o-visualization "${OUT_DIR}/core-metrics-results/weighted-unifrac-treatment-significance.qzv"
else
    echo ">> Weighted UniFrac significance already tested. Skipping."
fi

# ==========================================
# 6. ALPHA DIVERSITY SIGNIFICANCE (KRUSKAL-WALLIS)
# ==========================================
echo ">> Testing alpha diversity significance..."

# Shannon Diversity
if [ ! -f "${OUT_DIR}/core-metrics-results/shannon-group-significance.qzv" ]; then
    echo ">> Testing significance for Shannon Diversity..."
    qiime diversity alpha-group-significance \
      --i-alpha-diversity "${OUT_DIR}/core-metrics-results/shannon_vector.qza" \
      --m-metadata-file "$METADATA" \
      --o-visualization "${OUT_DIR}/core-metrics-results/shannon-group-significance.qzv"
else
    echo ">> Shannon significance already tested. Skipping."
fi

# Faith's Phylogenetic Diversity (Faith's PD)
if [ ! -f "${OUT_DIR}/core-metrics-results/faith-pd-group-significance.qzv" ]; then
    echo ">> Testing significance for Faith's PD..."
    qiime diversity alpha-group-significance \
      --i-alpha-diversity "${OUT_DIR}/core-metrics-results/faith_pd_vector.qza" \
      --m-metadata-file "$METADATA" \
      --o-visualization "${OUT_DIR}/core-metrics-results/faith-pd-group-significance.qzv"
else
    echo ">> Faith's PD significance already tested. Skipping."
fi

echo ">> Pipeline completed successfully!"