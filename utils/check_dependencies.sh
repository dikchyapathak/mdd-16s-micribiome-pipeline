#!/bin/bash
# ==============================================================================
# Pipeline Dependency Verification Utility Script
# Checks system availability and active versions for all required pipeline tools.
# ==============================================================================

echo "=========================================="
echo " Checking Pipeline Software Dependencies "
echo "=========================================="

MISSING_COUNT=0

# Helper function to check command status
check_tool() {
    local cmd=$1
    local name=$2
    if command -v "$cmd" &> /dev/null; then
        echo -e "[✔] $name is installed: $(which $cmd)"
    else
        echo -e "[✘] ERROR: $name ('$cmd') is NOT found in PATH!"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
}

echo ""
echo ">> Checking CLI Core Tools:"
check_tool "bash" "GNU Bash"
check_tool "curl" "cURL"
check_tool "wget" "Wget"
check_tool "awk"  "GNU Awk"
check_tool "sed"  "GNU Sed"

echo ""
echo ">> Checking Quality Control Tools:"
check_tool "fastp" "fastp (Adapter & Quality Trimming)"

echo ""
echo ">> Checking QIIME 2 Framework:"
check_tool "qiime" "QIIME 2 CLI"

if command -v qiime &> /dev/null; then
    echo "    QIIME 2 Version info:"
    qiime info | grep -E "QIIME 2 release|q2-" | head -n 5 | sed 's/^/      /'
fi

echo ""
echo "=========================================="
if [ "$MISSING_COUNT" -eq 0 ]; then
    echo " SUCCESS: All dependencies are satisfied!"
    echo "=========================================="
    exit 0
else
    echo " FAILURE: $MISSING_COUNT required tool(s) missing."
    echo " Please activate your Conda environment:"
    echo "   conda activate qiime2-amplicon-2024.2"
    echo "=========================================="
    exit 1
fi