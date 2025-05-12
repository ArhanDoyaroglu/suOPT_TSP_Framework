#!/bin/bash

# Script to verify the framework directory structure and identify unnecessary files
# Usage: ./verify_files.sh

echo "===================================================="
echo "  Verifying TSP Solver Comparison Framework Files"
echo "===================================================="

# Define expected main directories and files
EXPECTED_DIRS=(
    "benchmark"
    "benchmark/opt_known_euc"
    "benchmark/opt_unknown_euc"
    "benchmark/converters"
    "results_all_solvers"
    "scripts"
)

EXPECTED_FILES=(
    "setup_framework.sh"
    "run_all_solvers.sh"
    "uninstall_framework.sh"
    "README.md"
    "benchmark/converters/geo2euc_converter.py"
    "benchmark/converters/euc2fullmatrix_converter.py"
    "scripts/clean_framework.sh"
    "scripts/run_converters.sh"
    "scripts/generate_dimacs_instances.sh"
    "scripts/delete_dimacs_instances.sh"
)

SOLVER_DIRS=(
    "co031219"              # Concorde
    "LKH-3.0.13"            # LKH
    "GPUBasedACS-master"    # GPU ACS
    "PIHC_TSP-master"       # PIHC
)

# Check expected directories
echo "Checking expected directories..."
MISSING_DIRS=()
for dir in "${EXPECTED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        MISSING_DIRS+=("$dir")
    fi
done

if [ ${#MISSING_DIRS[@]} -gt 0 ]; then
    echo "Warning: Missing directories:"
    for dir in "${MISSING_DIRS[@]}"; do
        echo "  - $dir"
    done
else
    echo "All expected directories are present."
fi

# Check expected files
echo "Checking expected files..."
MISSING_FILES=()
for file in "${EXPECTED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "Warning: Missing files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
else
    echo "All expected files are present."
fi

# Check solver installations
echo "Checking solver installations..."
declare -A SOLVER_EXECS
SOLVER_EXECS["co031219/concorde/TSP/concorde"]="Concorde"
SOLVER_EXECS["LKH-3.0.13/LKH"]="LKH"
SOLVER_EXECS["GPUBasedACS-master/gpuants"]="GPU ACS"
SOLVER_EXECS["PIHC_TSP-master/parallel/pihc"]="PIHC"

for exec_path in "${!SOLVER_EXECS[@]}"; do
    if [ -f "$exec_path" ]; then
        echo "  - ${SOLVER_EXECS[$exec_path]}: Installed (executable found)"
    else
        if [ -d "$(dirname "$exec_path")" ]; then
            echo "  - ${SOLVER_EXECS[$exec_path]}: Source files present, but executable not found"
        else
            echo "  - ${SOLVER_EXECS[$exec_path]}: Not installed"
        fi
    fi
done

# Find potentially unnecessary files
echo "Checking for potentially unnecessary files..."

# Extensions commonly created by solvers or temporary files
TEMP_EXTENSIONS=("sol" "tour" "log" "json" "js" "tmp" "out" "err" "par" "pul" "sav" "res" "ext" "dat" "mas")

UNNECESSARY_FILES=()
for ext in "${TEMP_EXTENSIONS[@]}"; do
    # Find files with these extensions
    files=$(find . -maxdepth 1 -name "*.$ext" -type f)
    if [ -n "$files" ]; then
        while IFS= read -r file; do
            UNNECESSARY_FILES+=("$file")
        done <<< "$files"
    fi
done

# Check for archive files
archive_files=$(find . -maxdepth 1 -name "*.tgz" -o -name "*.zip" -o -name "*.tar.gz" -type f)
if [ -n "$archive_files" ]; then
    while IFS= read -r file; do
        UNNECESSARY_FILES+=("$file")
    done <<< "$archive_files"
fi

# Check for standalone converter files in the root directory (which should be in benchmark/converters)
if [ -f "geo2euc_converter.py" ] || [ -f "euc2fullmatrix_converter.py" ]; then
    echo "Warning: Converter scripts found in the root directory. They should be in benchmark/converters/"
    if [ -f "geo2euc_converter.py" ]; then
        UNNECESSARY_FILES+=("geo2euc_converter.py")
    fi
    if [ -f "euc2fullmatrix_converter.py" ]; then
        UNNECESSARY_FILES+=("euc2fullmatrix_converter.py")
    fi
fi

# Report unnecessary files
if [ ${#UNNECESSARY_FILES[@]} -gt 0 ]; then
    echo "The following unnecessary files were found:"
    for file in "${UNNECESSARY_FILES[@]}"; do
        echo "  - $file"
    done
    echo "You can safely remove these files with:"
    echo "  rm <filename>"
else
    echo "No unnecessary files found in the main directory."
fi

echo "===================================================="
echo "  Verification Complete!"
echo "===================================================="
echo ""
echo "If you want to remove solver executables while keeping the framework,"
echo "run the uninstall script: ./uninstall_framework.sh"
echo "" 