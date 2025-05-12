#!/bin/bash

# Script to remove TSP solver executables while preserving source files
# This only removes executables, not source code or libraries
# Usage: ./uninstall_framework.sh

echo "===================================================="
echo "  Removing TSP Solver Executables"
echo "===================================================="

# Define solver executables to remove
declare -A SOLVER_EXECS
SOLVER_EXECS["co031219/concorde/TSP/concorde"]="Concorde"
SOLVER_EXECS["LKH-3.0.13/LKH"]="LKH"
SOLVER_EXECS["GPUBasedACS-master/gpuants"]="GPU ACS"
SOLVER_EXECS["PIHC_TSP-master/parallel/pihc"]="PIHC"

# Define instance generator executables to remove
declare -A GENERATOR_EXECS
GENERATOR_EXECS["hard_tsp_instantiation/Tnm"]="TNM Generator"
GENERATOR_EXECS["DIMACS/portgen"]="DIMACS Generator (portgen)"
GENERATOR_EXECS["DIMACS/portcgen"]="DIMACS Generator (portcgen)"
GENERATOR_EXECS["DIMACS/portmgen"]="DIMACS Generator (portmgen)"
GENERATOR_EXECS["DIMACS/greedy"]="DIMACS Generator (greedy)"
GENERATOR_EXECS["DIMACS/length"]="DIMACS Generator (length)"

# Remove solver executables
echo "Removing solver executables..."
for exec_path in "${!SOLVER_EXECS[@]}"; do
    if [ -f "$exec_path" ]; then
        echo "Removing ${SOLVER_EXECS[$exec_path]} executable: $exec_path"
        rm -f "$exec_path"
    else
        echo "${SOLVER_EXECS[$exec_path]} executable not found: $exec_path"
    fi
done

# Remove instance generator executables
echo "Removing instance generator executables..."
for exec_path in "${!GENERATOR_EXECS[@]}"; do
    if [ -f "$exec_path" ]; then
        echo "Removing ${GENERATOR_EXECS[$exec_path]} executable: $exec_path"
        rm -f "$exec_path"
    else
        echo "${GENERATOR_EXECS[$exec_path]} executable not found: $exec_path"
    fi
done

# Remove object files from compilations
echo "Cleaning up object files..."
find co031219 -name "*.o" -type f -delete 2>/dev/null
find LKH-3.0.13 -name "*.o" -type f -delete 2>/dev/null
find GPUBasedACS-master -name "*.o" -type f -delete 2>/dev/null
find PIHC_TSP-master -name "*.o" -type f -delete 2>/dev/null
find hard_tsp_instantiation -name "*.o" -type f -delete 2>/dev/null
find DIMACS -name "*.o" -type f -delete 2>/dev/null

# Remove any result files
echo "Cleaning up result files..."
rm -rf results_all_solvers/*

echo "===================================================="
echo "  Cleanup Complete!"
echo "===================================================="
echo ""
echo "All solver and generator executables have been removed."
echo "Source files and libraries have been preserved."
echo ""
echo "To recompile everything, run: ./setup_framework.sh"
echo "" 