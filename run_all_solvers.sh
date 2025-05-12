#!/bin/bash

# Script to run every TSP instance on every solver and collect results
# Usage: 
#   ./run_all_solvers.sh           # Interactive mode
#   ./run_all_solvers.sh all       # Run all instances
#   ./run_all_solvers.sh single    # Run a single instance

# Define workspace root for absolute paths
WORKSPACE_ROOT="/home/users/arhandoyaroglu/suOPT"

# Function to extract instance size from filename
get_instance_size() {
  local filename=$(basename "$1" .tsp)
  local size=$(echo "$filename" | grep -o -E '[0-9]+' | head -1)
  if [ -z "$size" ]; then
    size=0
  fi
  echo "$size"
}

# Set paths for output directories
OUTPUT_DIR="$WORKSPACE_ROOT/results_all_solvers"
CONCORDE_OUTPUT="$OUTPUT_DIR/concorde"
LKH_OUTPUT="$OUTPUT_DIR/lkh"
GPUACS_OUTPUT="$OUTPUT_DIR/gpuacs"
PIHC_OUTPUT="$OUTPUT_DIR/pihc"

# Create output directories
mkdir -p "$CONCORDE_OUTPUT" "$LKH_OUTPUT" "$GPUACS_OUTPUT" "$PIHC_OUTPUT"

# Path to optimal values file for LKH
opt_file="$WORKSPACE_ROOT/benchmark/opt_known_val.txt"

# Read optimal values for LKH parameter files
declare -A opt_values
if [ -f "$opt_file" ]; then
  while IFS=' :' read -r name value; do
    opt_values["$name"]="$value"
  done < "$opt_file"
fi

# Define solvers with their actual executable paths (from the run scripts)
CONCORDE_EXEC="$WORKSPACE_ROOT/co031219/concorde/TSP/concorde"
LKH_EXEC="$WORKSPACE_ROOT/LKH-3.0.13/LKH"
GPUACS_EXEC="$WORKSPACE_ROOT/GPUBasedACS-master/gpuants"
PIHC_EXEC="$WORKSPACE_ROOT/PIHC_TSP-master/parallel/pihc"

# Output summary file
SUMMARY_FILE="$OUTPUT_DIR/results_summary.txt"

# Function to run all solvers on a specific instance
run_solvers_on_instance() {
  local instance="$1"
  local instance_name=$(basename "$instance" .tsp)
  
  # Get instance size (number of cities) from the filename 
  local instance_size=$(get_instance_size "$instance")
  if [ "$instance_size" = "0" ]; then
    instance_size="N/A"
  fi
  
  echo "Processing instance: $instance_name (Size: $instance_size)"

  # Use the absolute path for the instance
  local absolute_instance_path="$instance"

  # Run Concorde
  echo "Running Concorde on $instance_name..."
  local concorde_out_file="$CONCORDE_OUTPUT/${instance_name}_concorde.txt"
  local concorde_sol_file="$CONCORDE_OUTPUT/${instance_name}.sol"
  local temp_dir="$WORKSPACE_ROOT/temp/concorde"
  
  # Create temporary directory
  mkdir -p "$temp_dir"
  
  # Copy the instance file to temp directory
  local local_tsp_file="$temp_dir/$(basename "$absolute_instance_path")"
  cp "$absolute_instance_path" "$local_tsp_file"
  
  start_time=$(date +%s.%N)
  # Run from the temp directory to keep all temp files there
  cd "$temp_dir"
  $CONCORDE_EXEC "$(basename "$local_tsp_file")" > "$concorde_out_file" 2>&1
  concorde_status=$?
  end_time=$(date +%s.%N)
  runtime=$(echo "$end_time - $start_time" | bc)
  
  # Move any .sol file generated to the output directory
  for sol_file in "$temp_dir"/*.sol; do
    if [ -f "$sol_file" ] && [ "$sol_file" != "$temp_dir/*.sol" ]; then
      mv "$sol_file" "$concorde_sol_file"
      break
    fi
  done
  
  # Clean up intermediate files created by Concorde
  rm -f "$temp_dir"/*.pul "$temp_dir"/*.sav "$temp_dir"/*.res "$temp_dir"/*.ext "$temp_dir"/*.dat "$temp_dir"/*.mas "$temp_dir"/*.tsp
  
  # Return to workspace root for next steps
  cd "$WORKSPACE_ROOT"
  
  # Extract tour length
  tour_length="N/A"
  if [ -f "$concorde_out_file" ] && [ $concorde_status -eq 0 ]; then
    tour_length=$(grep "Optimal Solution:" "$concorde_out_file" | awk '{print $3}')
    if [ -z "$tour_length" ]; then
      tour_length="Error"
    fi
  else
    tour_length="Error"
  fi
  printf "%-10s | %-13s | %-8s | %-11s | %-16.6f\n" "$instance_name" "$instance_size" "concorde" "$tour_length" "$runtime" >> "$SUMMARY_FILE"

  # Run LKH
  echo "Running LKH on $instance_name..."
  # Create parameter file for LKH with proper settings
  local lkh_par_file="$LKH_OUTPUT/${instance_name}.par"
  local lkh_output_file="$LKH_OUTPUT/${instance_name}_lkh.txt"
  local lkh_tour_file="$LKH_OUTPUT/${instance_name}.tour"
  
  echo "SPECIAL" > "$lkh_par_file"
  echo "PROBLEM_FILE = $absolute_instance_path" >> "$lkh_par_file"
  # Add optimum value if known
  local optimum_value="${opt_values[$instance_name]}"
  if [[ -n "$optimum_value" ]]; then
    echo "OPTIMUM = $optimum_value" >> "$lkh_par_file"
    echo "STOP_AT_OPTIMUM = YES" >> "$lkh_par_file"
  fi
  echo "MAX_CANDIDATES = 6 SYMMETRIC" >> "$lkh_par_file"
  echo "RECOMBINATION = CLARIST" >> "$lkh_par_file"
  echo "MAX_TRIALS = 10000" >> "$lkh_par_file"
  echo "RUNS = 1" >> "$lkh_par_file"
  echo "SEED = 0" >> "$lkh_par_file"
  echo "TRACE_LEVEL = 1" >> "$lkh_par_file"
  echo "OUTPUT_TOUR_FILE = $lkh_tour_file" >> "$lkh_par_file"
  
  start_time=$(date +%s.%N)
  $LKH_EXEC "$lkh_par_file" > "$lkh_output_file" 2>&1
  lkh_status=$?
  end_time=$(date +%s.%N)
  runtime=$(echo "$end_time - $start_time" | bc)
  
  # Extract tour length (Cost.avg) and runtime (Time.total) from LKH output
  tour_length="N/A"
  lkh_runtime="N/A"
  if [ -f "$lkh_output_file" ] && [ $lkh_status -eq 0 ]; then
    # Get Cost.avg as requested
    cost_avg_line=$(grep "Cost.avg =" "$lkh_output_file")
    if [ -n "$cost_avg_line" ]; then
      tour_length=$(echo "$cost_avg_line" | awk '{print $3}' | tr -d ',')
    fi
    
    # Get Time.total as requested
    time_total_line=$(grep "Time.total =" "$lkh_output_file")
    if [ -n "$time_total_line" ]; then
      lkh_runtime=$(echo "$time_total_line" | awk '{print $3}' | tr -d ',')
      if [ -n "$lkh_runtime" ]; then
        runtime="$lkh_runtime"
      fi
    fi
    
    # If Cost.avg not found, try alternative formats
    if [ -z "$tour_length" ] || [ "$tour_length" == "N/A" ]; then
      cost_line=$(grep -E "Cost = [0-9]+" "$lkh_output_file" | tail -1)
      if [ -n "$cost_line" ]; then
        tour_length=$(echo "$cost_line" | grep -oE "[0-9]+" | head -1)
      fi
    fi
    
    if [ -z "$tour_length" ]; then
      tour_length="Error"
    fi
  else
    tour_length="Error"
  fi
  printf "%-10s | %-13s | %-8s | %-11s | %-16.6f\n" "$instance_name" "$instance_size" "lkh" "$tour_length" "$runtime" >> "$SUMMARY_FILE"

  # Run GPU ACS
  echo "Running GPU ACS on $instance_name..."
  local gpuacs_output_file="$GPUACS_OUTPUT/${instance_name}_gpuacs.txt"
  
  # Create output directory for GPU ACS
  mkdir -p "$GPUACS_OUTPUT"
  
  # ACS uses a specific algorithm and iterations
  local ALG="acs_gpu_alt"
  local ITER=1
  
  start_time=$(date +%s.%N)
  $GPUACS_EXEC --test "$absolute_instance_path" --outdir "$GPUACS_OUTPUT" --alg "$ALG" --iter "$ITER" > "$gpuacs_output_file" 2>&1
  gpuacs_status=$?
  end_time=$(date +%s.%N)
  measured_runtime=$(echo "$end_time - $start_time" | bc)
  
  # Extract tour length from "Final solution:" and runtime from "Calc. time:"
  tour_length="N/A"
  runtime="$measured_runtime"  # Default to measured runtime
  if [ -f "$gpuacs_output_file" ] && [ $gpuacs_status -eq 0 ]; then
    # Extract "Final solution:" for tour length (from the provided gpuacs.txt file)
    final_solution_line=$(grep "Final solution:" "$gpuacs_output_file")
    if [ -n "$final_solution_line" ]; then
      tour_length=$(echo "$final_solution_line" | awk '{print $3}')
    fi
    
    # Get the calc time from the LAST "Calc. time:" line in the file (not GPU Calc. time)
    # We need to get the last one which appears after "Run finished in" line
    # First, check if "Run finished in" appears before looking for Calc. time
    if grep -q "Run finished in" "$gpuacs_output_file"; then
      # Now extract the Calc. time that appears after this line
      calc_time=$(grep -A 3 "Run finished in" "$gpuacs_output_file" | grep -oE "Calc\. time: [0-9]+\.[0-9]+" | head -1 | grep -oE "[0-9]+\.[0-9]+")
      if [ -n "$calc_time" ]; then
        runtime="$calc_time"
      fi
    fi
    
    # If still no tour length, check in any available json files
    if [ -z "$tour_length" ] || [ "$tour_length" == "N/A" ]; then
      # Find any JSON files that might contain the tour length
      for js_file in "$GPUACS_OUTPUT/${instance_name}"*.js; do
        if [ -f "$js_file" ]; then
          best_value_line=$(grep "\"best_value\":" "$js_file")
          if [ -n "$best_value_line" ]; then
            tour_length=$(echo "$best_value_line" | grep -oE '[0-9]+' | head -1)
            break
          fi
        fi
      done
    fi
    
    if [ -z "$tour_length" ]; then
      tour_length="Error"
    fi
  else
    tour_length="Error"
  fi
  printf "%-10s | %-13s | %-8s | %-11s | %-16.6f\n" "$instance_name" "$instance_size" "gpuacs" "$tour_length" "$runtime" >> "$SUMMARY_FILE"

  # Run PIHC
  echo "Running PIHC on $instance_name..."
  local pihc_output_file="$PIHC_OUTPUT/${instance_name}_pihc.sol"
  
  # PIHC requires interactive inputs for initialization strategy and thread mapping
  # Using Nearest Neighbor (3) for init and TPR (1) for thread mapping
  local init_choice=3  # Nearest Neighbor
  local thread_choice=1  # TPR
  
  start_time=$(date +%s.%N)
  # Feed inputs to PIHC
  {
    echo "$init_choice"
    echo "$thread_choice"
  } | $PIHC_EXEC "$absolute_instance_path" > "$pihc_output_file" 2>&1
  pihc_status=$?
  end_time=$(date +%s.%N)
  measured_runtime=$(echo "$end_time - $start_time" | bc)
  
  # Extract "Minimal Distance" as tour length and "time :" as runtime
  tour_length="N/A"
  pihc_runtime="N/A"
  if [ -f "$pihc_output_file" ] && [ $pihc_status -eq 0 ]; then
    # Extract "Minimal Distance" for tour length as requested - handle space before colon
    min_distance_line=$(grep -E "Minimal Distance\s*:" "$pihc_output_file")
    if [ -n "$min_distance_line" ]; then
      # Use a different approach to extract the number - get the last field
      tour_length=$(echo "$min_distance_line" | awk '{print $NF}')
    fi
    
    # If not found, try alternative format
    if [ -z "$tour_length" ] || [ "$tour_length" == "N/A" ]; then
      min_distance_line=$(grep -i "minimal" "$pihc_output_file")
      if [ -n "$min_distance_line" ]; then
        tour_length=$(echo "$min_distance_line" | grep -oE '[0-9]+' | head -1)
      fi
    fi
    
    # Extract runtime from "time : X" at the end
    time_line=$(grep -E "time\s*:" "$pihc_output_file" | tail -1)
    if [ -n "$time_line" ]; then
      pihc_runtime=$(echo "$time_line" | grep -oE '[0-9]+\.[0-9]+')
      if [ -n "$pihc_runtime" ]; then
        runtime="$pihc_runtime"
      else
        runtime="$measured_runtime"
      fi
    else
      runtime="$measured_runtime"
    fi
    
    if [ -z "$tour_length" ]; then
      tour_length="Error"
    fi
  else
    tour_length="Error"
    runtime="$measured_runtime"
  fi
  printf "%-10s | %-13s | %-8s | %-11s | %-16.6f\n" "$instance_name" "$instance_size" "pihc" "$tour_length" "$runtime" >> "$SUMMARY_FILE"

  echo "Completed all solvers for instance: $instance_name"
}

# Function to run in interactive mode
run_interactive() {
  echo "TSP Solver Testing Framework"
  echo "============================"
  echo "1. Run all instances (sorted by size)"
  echo "2. Run a single instance"
  echo ""
  read -p "Enter your choice (1/2): " choice
  
  case "$choice" in
    1)
      run_all_instances
      ;;
    2)
      run_single_instance
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
}

# Function to run all instances
run_all_instances() {
  # Create or clear the summary file with a better format
  echo "Instance | Instance Size | Solver   | Tour Length | Runtime (seconds)" > "$SUMMARY_FILE"
  echo "---------|---------------|----------|-------------|------------------" >> "$SUMMARY_FILE"

  # Find all benchmark folders that end with _euc
  BENCHMARK_FOLDERS=()
  for folder in $WORKSPACE_ROOT/benchmark/*_euc; do
    if [ -d "$folder" ]; then
      BENCHMARK_FOLDERS+=("$folder")
    fi
  done

  # Process each benchmark folder
  for folder in "${BENCHMARK_FOLDERS[@]}"; do
    echo "Processing folder: $folder"

    # Find all TSP instances in the folder and sort them by size
    instances=()
    for instance in "$folder"/*.tsp; do
      if [ -f "$instance" ]; then
        instances+=("$instance")
      fi
    done

    # If no instances found, skip
    if [ ${#instances[@]} -eq 0 ]; then
      echo "Warning: No TSP instances found in $folder. Skipping."
      continue
    fi

    # Sort instances by size (numeric part in filename)
    sorted_instances=()
    for instance in "${instances[@]}"; do
      size=$(get_instance_size "$instance")
      # Add size as prefix for sorting
      sorted_instances+=("$size:$instance")
    done

    # Sort the instances by size prefix
    IFS=$'\n' sorted_instances=($(sort -n <<<"${sorted_instances[*]}"))
    unset IFS

    # Process each instance after removing the size prefix
    for item in "${sorted_instances[@]}"; do
      instance="${item#*:}"
      run_solvers_on_instance "$instance"
    done
  done

  # Generate a more readable summary report with detailed spacing
  generate_summary_report
}

# Function to run a single instance
run_single_instance() {
  # Create or clear the summary file with a better format
  echo "Instance | Instance Size | Solver   | Tour Length | Runtime (seconds)" > "$SUMMARY_FILE"
  echo "---------|---------------|----------|-------------|------------------" >> "$SUMMARY_FILE"

  # Ask user for instance path
  echo "Enter the full path to the TSP instance file:"
  read -p "Path: " instance_path
  
  # Check if file exists
  if [ ! -f "$instance_path" ]; then
    echo "Error: File not found: $instance_path"
    exit 1
  fi
  
  # Run solvers on the instance
  run_solvers_on_instance "$instance_path"
  
  # Generate a more readable summary report with detailed spacing
  generate_summary_report
}

# Function to generate summary report
generate_summary_report() {
  READABLE_SUMMARY="$OUTPUT_DIR/summary_report.txt"
  echo "===================================================================" > "$READABLE_SUMMARY"
  echo "|                  TSP SOLVER COMPARISON REPORT                   |" >> "$READABLE_SUMMARY"
  echo "===================================================================" >> "$READABLE_SUMMARY"
  echo "" >> "$READABLE_SUMMARY"
  echo "Generated on: $(date)" >> "$READABLE_SUMMARY"
  echo "" >> "$READABLE_SUMMARY"

  # Copy the formatted data directly
  cat "$SUMMARY_FILE" >> "$READABLE_SUMMARY"

  # Add statistics section
  echo "" >> "$READABLE_SUMMARY"
  echo "Solver Statistics:" >> "$READABLE_SUMMARY"
  echo "----------------" >> "$READABLE_SUMMARY"

  # Calculate statistics by solver
  for solver in "concorde" "lkh" "gpuacs" "pihc"; do
    # Count instances
    instance_count=$(grep -c " $solver " "$SUMMARY_FILE")
    
    # Get average tour length and runtime
    if [ $instance_count -gt 0 ]; then
      echo "  $solver: Processed $instance_count instances" >> "$READABLE_SUMMARY"
    fi
  done

  echo "" >> "$READABLE_SUMMARY"
  echo "End of report" >> "$READABLE_SUMMARY"

  echo "Results saved to:"
  echo "- Summary format: $SUMMARY_FILE"
  echo "- Readable format: $READABLE_SUMMARY"
}

# Main script execution
if [ $# -eq 0 ]; then
  # No arguments - run in interactive mode
  run_interactive
elif [ "$1" = "all" ]; then
  # Run all instances
  run_all_instances
elif [ "$1" = "single" ]; then
  # Run a single instance
  run_single_instance
else
  echo "Invalid argument. Usage:"
  echo "  ./run_all_solvers.sh           # Interactive mode"
  echo "  ./run_all_solvers.sh all       # Run all instances"
  echo "  ./run_all_solvers.sh single    # Run a single instance"
  exit 1
fi 