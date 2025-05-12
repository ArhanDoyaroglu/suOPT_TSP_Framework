#!/bin/bash

# Directories and executable
benchmark_dir="/home/users/arhandoyaroglu/suOPT/benchmark"
output_dir="/home/users/arhandoyaroglu/suOPT/outputs/lkh"
lkh_executable="/home/users/arhandoyaroglu/suOPT/LKH-3.0.13/LKH"
opt_file="/home/users/arhandoyaroglu/suOPT/benchmark/opt_known_val.txt"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Read optimal values into associative array
declare -A opt_values
while IFS=' :' read -r name value; do
    opt_values["$name"]="$value"
done < "$opt_file"

# Ask for mTSP configuration
read -p "Enter number of salesmen (1 for regular TSP): " salesmen
if [[ "$salesmen" -gt 1 ]]; then
    mtsp_mode="YES"
else
    mtsp_mode="NO"
fi

# Benchmark input folders
input_dirs=(
    "$benchmark_dir/opt_known_euc"
    "$benchmark_dir/opt_known_noteuc"
    "$benchmark_dir/opt_unknown_euc"
)

# Loop through all TSP files in the input folders
for dir in "${input_dirs[@]}"; do
    for file in "$dir"/*.tsp; do
        if [[ -f "$file" ]]; then
            filename=$(basename "$file" .tsp)
            par_file="$output_dir/${filename}.par"
            tour_file="$output_dir/${filename}.tour"
            lkh_output_file="$output_dir/${filename}.log"

            optimum_value="${opt_values[$filename]}"

            echo "SPECIAL" > "$par_file"
            echo "PROBLEM_FILE = $file" >> "$par_file"
            if [[ -n "$optimum_value" ]]; then
                echo "OPTIMUM = $optimum_value" >> "$par_file"
            fi
            echo "MAX_CANDIDATES = 6 SYMMETRIC" >> "$par_file"
            echo "RECOMBINATION = CLARIST" >> "$par_file"
            echo "MAX_TRIALS = 10000" >> "$par_file"
            echo "RUNS = 1" >> "$par_file"
            echo "SEED = 0" >> "$par_file"
            echo "TRACE_LEVEL = 1" >> "$par_file"
            echo "OUTPUT_TOUR_FILE = $tour_file" >> "$par_file"

            if [[ "$mtsp_mode" == "YES" ]]; then
                echo "SALESMEN = $salesmen" >> "$par_file"
                echo "MTSP_MIN_SIZE = 1" >> "$par_file"
                echo "MTSP_OBJECTIVE = MINSUM" >> "$par_file"
                echo "MTSP_SOLUTION_FILE = $output_dir/${filename}_mtsp.tour" >> "$par_file"
            fi

            # Run LKH
            "$lkh_executable" "$par_file" | tee "$lkh_output_file"
            echo "Solved: $file -> $tour_file"
        fi
    done
done
