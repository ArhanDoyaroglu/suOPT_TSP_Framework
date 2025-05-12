#!/bin/bash

# Ask for Initial Solution Setup Approach (1-8)
echo "Choose an initial solution setup approach:"
echo "1. Sequenced"
echo "2. Random"
echo "3. Nearest Neighbor (NN)"
echo "4. NI"
echo "5. Greedy"
echo "6. MST"
echo "7. Christofides"
echo "8. Clarke-Wright"
read -p "Enter a number (1-8): " init_choice

# Ask for CUDA Thread Mapping Strategy (1-4)
echo "Choose a CUDA thread mapping strategy:"
echo "1. TPR"
echo "2. TPRED"
echo "3. TPRC"
echo "4. TPN"
read -p "Enter a number (1-4): " thread_choice

# Path to PIHC executable
pihc_exec="/home/users/arhandoyaroglu/suOPT/PIHC_TSP-master/parallel/pihc"

# Input directories
KNOWN_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_known_euc"
UNKNOWN_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_unknown_euc"
output_dir="/home/users/arhandoyaroglu/suOPT/outputs/gpuPIHC"

# Ensure output directory exists
mkdir -p "$output_dir"

# Loop through all TSP instances in both directories
for dir in "$KNOWN_DIR" "$UNKNOWN_DIR"; do
    for file in "$dir"/*.tsp; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file" .tsp)
            echo "Solving: $file with approach $init_choice and thread strategy $thread_choice"

            "$pihc_exec" "$file" <<< "$init_choice"$'\n'"$thread_choice" > "$output_dir/${filename}_pihc.sol"

            echo "Saved solution: $output_dir/${filename}_pihc.sol"
        fi
    done
done
