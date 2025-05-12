#!/bin/bash

# Define directories (use absolute paths)
benchmark_dir="/home/users/arhandoyaroglu/suOPT/benchmark"
output_dir="/home/users/arhandoyaroglu/suOPT/outputs/concorde"
concorde_executable="/home/users/arhandoyaroglu/suOPT/co031219/concorde/TSP/concorde"
scripts_dir="/home/users/arhandoyaroglu/suOPT/scripts"
target_base="/home/users/arhandoyaroglu/suOPT/tours"
target_concorde="$target_base/concorde_tours"
temp_dir="/home/users/arhandoyaroglu/suOPT/temp/concorde"

# Input directories (ONLY these are used now)
input_dirs=(
    "$benchmark_dir/opt_known_euc"
    "$benchmark_dir/opt_known_noteuc"
    "$benchmark_dir/opt_unknown_euc"
)

# Ensure output and target directories exist
mkdir -p "$output_dir"
mkdir -p "$target_concorde"
mkdir -p "$temp_dir"

# Clean up any existing temp files before starting
cleanup_temp_dir() {
    echo "Cleaning up temporary files in $temp_dir"
    rm -f "$temp_dir"/*.pul "$temp_dir"/*.sav "$temp_dir"/*.res "$temp_dir"/*.ext "$temp_dir"/*.dat "$temp_dir"/*.mas "$temp_dir"/*.sol
}

# Initial cleanup
cleanup_temp_dir

# Process each TSP file in the specified input directories
for dir in "${input_dirs[@]}"; do
    find "$dir" -type f -name "*.tsp" -exec du -b {} + | sort -n | cut -f2- | while read file; do
        output_file="${output_dir}/${file#${benchmark_dir}/}"
        output_file="${output_file%.tsp}.sol"

        # Skip if solution exists and is non-empty
        if [[ -s "$output_file" ]]; then
            echo "Skipping: $file (solution already exists and is non-empty)"
            continue
        fi

        # Create necessary directories
        mkdir -p "$(dirname "$output_file")"

        # Get the filename without the path
        local_filename=$(basename "$file")
        
        # Change to temporary directory for running Concorde
        cd "$temp_dir"
        
        # Copy the instance file to the temp directory
        cp "$file" "$temp_dir/"
        
        # Solve with Concorde using the local copy of the file
        echo "Solving: $file"
        "$concorde_executable" "$local_filename" > "$output_file" 2>&1
        
        # Check if concorde produced output
        if [[ ! -s "$output_file" ]]; then
            echo "Warning: $output_file is empty, retrying..."
            rm -f "$output_file"
            "$concorde_executable" "$local_filename" > "$output_file" 2>&1
        fi

        # Move any .sol file generated in temp directory to the tours directory
        for sol_file in "$temp_dir"/*.sol; do
            if [[ -f "$sol_file" ]] && [[ "$sol_file" != "$temp_dir/*.sol" ]]; then
                mv "$sol_file" "$target_concorde/$(basename "$file" .tsp).sol"
                echo "Moved $(basename "$sol_file") to $target_concorde"
            fi
        done

        # Delete temporary files created by Concorde in temp directory
        # This includes the copied TSP file and all generated files
        rm -f "$temp_dir"/*.pul "$temp_dir"/*.sav "$temp_dir"/*.res "$temp_dir"/*.ext "$temp_dir"/*.dat "$temp_dir"/*.mas "$temp_dir"/*.tsp
        
        echo "Finished processing $file"
    done
done

echo "All Concorde tour files moved to: $target_concorde"
echo "Any temporary files have been cleaned up"
