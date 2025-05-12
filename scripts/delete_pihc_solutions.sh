#!/bin/bash

# GPU PIHC output directory
output_dir="/home/users/arhandoyaroglu/suOPT/outputs/gpuPIHC"

# Ask for confirmation
read -p "Are you sure you want to delete all .sol files in outputs/gpuPIHC/? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Deletion cancelled."
    exit 1
fi

# File extensions to delete (.sol)
echo "Deleting GPU PIHC .sol files in: $output_dir"

find "$output_dir" -type f -name "*.sol" -exec rm -v {} \;

echo "All GPU PIHC solution files deleted."
