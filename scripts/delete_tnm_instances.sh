#!/bin/bash

# Directory where Tnm instances were stored
TARGET_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_unknown_euc"

# Pattern for Tnm files
FILE_PATTERN="Tnm*.tsp"

# Ask for confirmation
read -p "Are you sure you want to delete all tnm instances in benchmark/opt_unknown_euc? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Deletion cancelled."
    exit 1
fi

# Delete matching files
echo "Deleting Tnm-generated files in $TARGET_DIR..."
rm -f "$TARGET_DIR"/$FILE_PATTERN

echo "Deleted all files matching: $FILE_PATTERN from $TARGET_DIR"
