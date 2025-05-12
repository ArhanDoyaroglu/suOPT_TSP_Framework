#!/bin/bash

# Path to compiled Tnm generator
Tnm_exec="/home/users/arhandoyaroglu/suOPT/hard_tsp_instantiation/Tnm"

# Output directory for Tnm instances
OUTPUT_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_unknown_euc"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Ask user how many instances to generate
read -p "How many Tnm instances do you want to generate? " TARGET_COUNT

# Generate random valid Tnm instances (N > 50 and N % 3 == 1)
count=0
while [ $count -lt $TARGET_COUNT ]; do
    N=$(( (RANDOM % 9950) + 51 ))
    remainder=$(( N % 3 ))
    if [ $remainder -ne 1 ]; then
        continue  # skip if not valid (we need N % 3 == 1)
    fi

    echo "Generating Tnm$N.tsp..."
    "$Tnm_exec" "$N"
    if [ -f "Tnm$N.tsp" ]; then
        mv "Tnm$N.tsp" "$OUTPUT_DIR/Tnm$N.tsp"
        echo "Moved Tnm$N.tsp to $OUTPUT_DIR"
        count=$((count + 1))
    fi

done

echo "$TARGET_COUNT random Tnm instances have been generated and moved to: $OUTPUT_DIR"