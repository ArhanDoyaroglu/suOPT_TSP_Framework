#!/bin/bash

# Concorde solution directories
concorde_output_dir="/home/users/arhandoyaroglu/suOPT/outputs/concorde"
concorde_tours_dir="/home/users/arhandoyaroglu/suOPT/tours/concorde_tours"



# Ask for confirmation
read -p "Are you sure you want to delete all .sol files in outputs/concorde/ and tours/concorde_tours? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Deletion cancelled."
    exit 1
fi

# Delete Concorde .sol files from both locations
echo "Deleting Concorde solution files (*.sol) in: $concorde_output_dir and $concorde_tours_dir"

find "$concorde_output_dir" -type f -name "*.sol" -exec rm -v {} \;
find "$concorde_tours_dir" -type f -name "*.sol" -exec rm -v {} \;

echo "All Concorde solution files deleted from both directories."
