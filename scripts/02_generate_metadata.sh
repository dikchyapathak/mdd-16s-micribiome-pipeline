#!/bin/bash

# Base directory for the project — UPDATE THIS to your local path, or export
# BASE_DIR as an environment variable before running.
BASE_DIR="${BASE_DIR:-/path/to/mdd-16s-microbiome-pipeline}"

# Define input and output files
INPUT_FILE="${BASE_DIR}/metadata/SraRunTable.txt"
OUTPUT_FILE="${BASE_DIR}/metadata/metadata.tsv"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

echo ">> Stripping Windows line endings from input file..."
# This removes \r characters to prevent QIIME 2 empty-ID or formatting glitches
sed -i 's/\r//g' "$INPUT_FILE"

echo ">> Processing full metadata table and appending Phenotype column safely..."

awk '
BEGIN {
    FS="\t"; 
    OFS="\t";
}
NR==1 {
    # 1. Clean up and modify the header row
    for(i=1; i<=NF; i++) {
        header = $i;
        # Replace spaces and special characters with underscores to satisfy QIIME 2
        gsub(/[[:space:]\(\)\-\/]+/, "_", header);
        
        # Ensure the first column is exactly #SampleID
        if (i == 1) {
            header = "#SampleID";
        }
        
        # Track where the Sample Name column is for phenotype logic
        if ($i ~ /Sample Name/) name_col = i;
        
        headers[i] = header;
    }
    
    # Print the cleaned headers, appending our new Phenotype column at the end
    for(i=1; i<=NF; i++) {
        printf "%s%s", headers[i], OFS;
    }
    print "Phenotype";
}
NR>1 {
    # CRITICAL FIX: Skip this row if the entire line is empty or if the first column ID is blank
    if ($0 == "" || $1 ~ /^[[:space:]]*$/ || $1 == "") {
        next;
    }

    # 2. Determine Phenotype based on the prefix rules
    sample_name = $name_col;
    if (sample_name ~ /^BJHLGP/) {
        phenotype = "MDD_Patient";
    } else if (sample_name ~ /^BJHLGHG/) {
        phenotype = "Healthy_Control";
    } else {
        phenotype = "Unknown";
    }
    
    # Print all original column data for this row, then append the phenotype
    for(i=1; i<=NF; i++) {
        printf "%s%s", $i, OFS;
    }
    print phenotype;
}' "$INPUT_FILE" > "$OUTPUT_FILE"

echo ">> Done! Complete QIIME 2 metadata saved safely to: $OUTPUT_FILE"

# Quick summary validation to show you it worked
echo ">> Summary of parsed Phenotypes:"
echo "------------------------------"
tail -n +2 "$OUTPUT_FILE" | awk -F"\t" '{print $NF}' | sort | uniq -c