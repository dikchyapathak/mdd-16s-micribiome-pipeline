# 16S rRNA Microbiome Analysis Pipeline — Major Depressive Disorder (MDD) Study

A reproducible QIIME 2 + fastp pipeline for processing paired-end 16S rRNA amplicon
sequencing data to compare gut microbiome composition and diversity between MDD
patients and healthy controls.

## Data overview
For this analysis, I used the publicly available dataset that compared the gut microbiome between healthy individuals and MDD patients. The following is the overview of the dataset I used:\
**General Information**\
**BioProject**: PRJNA687871\
Total Number of Samples: 81\
Organism: Homo sapiens (Human)\
Tissue / Sample Source: Fecal/Stool samples (≥1 g)\
Collection Location: Beijing, China (Beijing Huilongguan Hospital)\
**Experimental Metadata**\
Control / Treatment:\
Disease Group (MDD): 36 patients diagnosed with Major Depressive Disorder (depressive episode of at least moderate severity).\
Control Group (HC): 45 Healthy Controls (no history of psychiatric disorders).\
Timepoints: Single timepoint (Cross-sectional). Samples were collected within 2 days after hospital admission or after a drug elution period.


## Pipeline Overview

1. **Download** — Fetch raw FASTQ files from ENA using SRA accessions.
2. **Metadata generation** — Clean and reformat the SRA run table into a
   QIIME 2-compatible metadata file, deriving a `Phenotype` column
   (MDD_Patient / Healthy_Control) from sample naming conventions.
3. **Quality control** — Adapter trimming and quality filtering with `fastp`.
4. **QIIME 2 import** — Build a manifest and import trimmed reads as a
   QIIME 2 artifact.
5. **Denoising / clustering** — Dereplicate and cluster sequences into
   97% OTUs with `vsearch`.
6. **Chimera filtering & core diversity** — Remove chimeric sequences, build a
   phylogenetic tree, assign taxonomy (SILVA classifier), and run core
   diversity metrics with PERMANOVA/Kruskal-Wallis significance testing.
7. **Alternative taxonomy/phylogeny path** — Same as step 6 but using the
   Greengenes2 classifier (kept as a separate script for comparison).

## Prerequisites

- [QIIME 2](https://docs.qiime2.org/) 
- [fastp](https://github.com/OpenGene/fastp)
- `wget` and `curl`
- Bash (Linux/macOS/WSL)

Install QIIME 2 via conda following the [official instructions](https://docs.qiime2.org/),
then activate the environment before running any script:

```bash
conda activate qiime2-2024.2
```

## ⚠️ Important: Update the Path Variables Before Running

These scripts were originally developed on a Windows/WSL machine and used
hardcoded absolute paths (e.g.
`/mnt/c/Users/dpathak/OneDrive - University of Arkansas/...`). They have been
refactored so that **every path derives from a single `BASE_DIR` variable** at
the top of each script.

**Before running any script**, open it and set `BASE_DIR` to the absolute path
of your cloned repository, for example:

```bash
BASE_DIR="/home/youruser/mdd-16s-microbiome-pipeline"
```

Alternatively, export it once in your shell so every script picks it up
automatically:

```bash
export BASE_DIR="/home/youruser/mdd-16s-microbiome-pipeline"
```

All subdirectories (`Raw_data`, `QC_data`, `Trimmed_data`, `Results`,
`metadata`) are derived from `BASE_DIR` and will be created automatically if
they don't exist. You do not need to edit any other path in the scripts.

## Usage

Run scripts in order from the repository root:

```bash
# 1. Download raw FASTQ files from ENA
bash scripts/01_download.sh

# 2. Generate QIIME 2-compatible metadata with Phenotype labels
bash scripts/02_generate_metadata.sh

# 3. Quality control / trimming
bash scripts/03_quality_control.sh

# 4. Import trimmed reads into QIIME 2
bash scripts/04_qiime_import.sh

# 5. Dereplicate and cluster into OTUs
bash scripts/05_qiime_denoise.sh

# 6. Chimera filtering, phylogeny, taxonomy, diversity (SILVA path)
bash scripts/06_chimera_diversity.sh

# 7. Alternative taxonomy/phylogeny/diversity path (Greengenes2)
bash scripts/07_qiime_phylogeny.sh
```

## Data

| File/Folder | Description |
|---|---|
| `metadata/SraRunTable.txt` | Raw SRA run table (input) |
| `metadata/SRR_Acc_List.txt` | List of SRA accessions to download |
| `metadata/metadata.tsv` | Cleaned QIIME 2 metadata (generated) |
| `docs/fpsyt-12-645045.pdf` | Reference paper for this dataset/study design |
| `Raw_data/` | Downloaded raw FASTQ files (gitignored, ~162 files) |
| `QC_data/` | fastp HTML/JSON/log reports (gitignored, ~233 files) |
| `Trimmed_data/` | QC-trimmed FASTQ files (gitignored, ~152 files) |
| `Results/` | QIIME 2 `.qza`/`.qzv` artifacts (gitignored) |

## Notes

- `Phenotype` is currently derived from a sample-name prefix rule
  (`BJHLGP` → MDD_Patient, `BJHLGHG` → Healthy_Control). Confirm this matches
  your own dataset's naming convention before relying on it.
- Sampling depth for core diversity metrics (`SAMPLING_DEPTH` in script 6,
  hardcoded value in script 7) should be chosen based on the
  `table-nonchimeric.qzv` / `table-summary.qzv` rarefaction curves — inspect
  these in [QIIME 2 View](https://view.qiime2.org/) before finalizing.
- Script 6 downloads the SILVA 138 classifier; script 7 downloads Greengenes2.
  Both are large (>100 MB) and only fetched once (cached checks are built in).

