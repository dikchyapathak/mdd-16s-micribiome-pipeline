#!/bin/bash

# Base directory for the project — UPDATE THIS to your local path, or export
# BASE_DIR as an environment variable before running.
BASE_DIR="${BASE_DIR:-/path/to/mdd-16s-microbiome-pipeline}"

# Define pathways and variables
RAW_DIR="${BASE_DIR}/Raw_data"

# File containing the list of accessions
ACCESSION_LIST="${BASE_DIR}/metadata/SRR_Acc_List.txt"

# Create the target directory if it doesn't exist
mkdir -p "$RAW_DIR"

# Check if the accession list file exists
if [ ! -f "$ACCESSION_LIST" ]; then
    echo "Error: $ACCESSION_LIST not found!"
    exit 1
fi

echo "Starting direct FASTQ downloads from ENA..."

# Loop through each line (accession number) in the file
while IFS= read -r SRR; do
    # Clean up carriage returns
    SRR=$(echo "$SRR" | tr -d '\r')
    [ -z "$SRR" ] && continue
    
    echo "-----------------------------------"
    echo "Processing $SRR..."
    
    # Query ENA API to get the FTP links for the FASTQ files
    # The API returns a TSV. We use tail -n 1 to skip the header.
    FTP_LINKS=$(curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${SRR}&result=read_run&fields=fastq_ftp&format=tsv" | tail -n 1)
    
    # Check if links were found
    if [ -z "$FTP_LINKS" ]; then
        echo "Warning: No FASTQ links found for $SRR on ENA."
        continue
    fi

    # ENA returns paired-end links separated by a semicolon (;)
    # We replace the semicolon with a space so we can loop through them
    LINKS_SPACED=$(echo "$FTP_LINKS" | tr ';' ' ')

    for LINK in $LINKS_SPACED; do
        # Extract the filename from the URL (e.g., SRR13307309_1.fastq.gz)
        FILENAME=$(basename "$LINK")
        
        echo "Downloading $FILENAME..."
        
        # Download the FASTQ file using wget. 
        # Using wget here as it handles FTP links very smoothly.
        wget -c "ftp://${LINK}" -O "${RAW_DIR}/${FILENAME}"
        
        # Alternatively, if you want to use curl, comment the wget line above and uncomment below:
        # curl -C - -L "ftp://${LINK}" -o "${RAW_DIR}/${FILENAME}"
    done

done < "$ACCESSION_LIST"

echo "-----------------------------------"
echo "All FASTQ downloads completed and saved to $RAW_DIR!"