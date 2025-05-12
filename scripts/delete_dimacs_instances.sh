#!/bin/bash

# Directory where DIMACS-generated files are stored
TARGET_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_unknown_euc"

# Pattern for DIMACS files (e.g., E1k_1.tsp, E1k_2.tsp, ...)
FILE_PATTERN="E1k_*.tsp"

# Ask for confirmation
read -p "Are you sure you want to delete all DIMACS instances in benchmark/opt_unkown_euc? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Deletion cancelled."
    exit 1
fi

# Delete matching files
echo "Deleting DIMACS-generated files in $TARGET_DIR..."
rm -f "$TARGET_DIR"/$FILE_PATTERN

echo "Deleted all files matching: $FILE_PATTERN"
