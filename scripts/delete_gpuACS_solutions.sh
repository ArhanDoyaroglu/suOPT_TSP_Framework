#!/bin/bash

# GPU ACS output directory
output_dir="/home/users/arhandoyaroglu/suOPT/outputs/gpuACS"

# Ask for confirmation
read -p "Are you sure you want to delete all js files in outputs/gpuACS? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Deletion cancelled."
    exit 1
fi

# File extensions to delete (updated to JSON output)
echo "Deleting GPU ACS output JSON files in: $output_dir"

find "$output_dir" -type f -name "*.js" -exec rm -v {} \;

echo "All GPU ACS JSON solution files deleted."