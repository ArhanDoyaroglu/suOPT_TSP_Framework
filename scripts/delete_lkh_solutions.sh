#!/bin/bash

output_dir="/home/users/arhandoyaroglu/suOPT/outputs/lkh"

# Ask for confirmation
read -p "Are you sure you want to delete all .tour and .par files in outputs/lkh/? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Deletion cancelled."
    exit 1
fi

# Delete all .tour and .par files
rm -f "$output_dir"/*.tour "$output_dir"/*.par "$output_dir"/*.log

echo "All .tour, .par and .log files in outputs/lkh/ have been deleted."
