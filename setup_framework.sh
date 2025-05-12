#!/bin/bash

# Setup script for TSP Solver Comparison Framework
# This script compiles the solvers and instance generators from existing source files
# Usage: ./setup_framework.sh

echo "===================================================="
echo "  Setting up TSP Solver Comparison Framework"
echo "===================================================="

# Create workspace structure if it doesn't exist
mkdir -p benchmark/opt_known_euc
mkdir -p benchmark/opt_unknown_euc
mkdir -p results_all_solvers

# Define current directory as workspace root
WORKSPACE_ROOT=$(pwd)
echo "Workspace root: $WORKSPACE_ROOT"

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "Checking dependencies..."
DEPS=("gcc" "g++" "make" "bc" "python3" "nvcc")
MISSING_DEPS=()

for dep in "${DEPS[@]}"; do
  if ! command_exists "$dep"; then
    MISSING_DEPS+=("$dep")
  fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  echo "Missing dependencies: ${MISSING_DEPS[*]}"
  echo "Please install these dependencies before continuing."
  echo "For Ubuntu/Debian: sudo apt-get install build-essential bc python3 nvidia-cuda-toolkit libgsl-dev libqsopt-dev"
  echo "For CentOS/RHEL: sudo yum install gcc gcc-c++ make bc python3 cuda-toolkit gsl-devel"
  echo "For other distributions, use your package manager to install the equivalent packages."
  exit 1
fi

# PART 1: BUILD SOLVERS
echo "===================================================="
echo "  BUILDING SOLVERS"
echo "===================================================="

# Build Concorde if source directory exists - with proper dependency checks
echo "Setting up Concorde..."
if [ -d "co031219/concorde" ] && [ ! -f "co031219/concorde/TSP/concorde" ]; then
  # Use specific QSopt path as specified by user
  QSOPT_PATH="/home/users/arhandoyaroglu/suOPT/qsopt"
  
  echo "Using QSopt at $QSOPT_PATH"
  cd co031219/concorde
  ./configure --with-qsopt=$QSOPT_PATH
  
  # Build with make
  make
  
  # Check if concorde binary was created
  if [ -f "TSP/concorde" ]; then
    echo "Concorde compiled successfully."
  else
    echo "Concorde TSP solver not built. Check for errors."
    echo "Verify that QSopt is correctly installed at $QSOPT_PATH"
  fi
  
  cd ../..
elif [ -f "co031219/concorde/TSP/concorde" ]; then
  echo "Concorde executable already exists. Skipping compilation."
else
  echo "Concorde source directory not found. Skipping compilation."
  echo "Expected directory structure: 'co031219/concorde' directory containing configure script"
fi

# Build LKH if source directory exists
echo "Setting up LKH..."
if [ -d "LKH-3.0.13" ] && [ ! -f "LKH-3.0.13/LKH" ]; then
  cd LKH-3.0.13
  make
  cd ..
  echo "LKH compiled successfully."
elif [ -f "LKH-3.0.13/LKH" ]; then
  echo "LKH executable already exists. Skipping compilation."
else
  echo "LKH source directory not found. Skipping compilation."
fi

# Build GPU-ACS if source directory exists - following the README instructions
echo "Setting up GPU-ACS..."
if [ -d "GPUBasedACS-master" ] && [ ! -f "GPUBasedACS-master/gpuants" ]; then
  if command_exists nvcc; then
    cd GPUBasedACS-master
    
    # Check for CUDA GPU architecture
    CUDA_ARCH=$(nvcc --version | grep -o "release [0-9]\+\.[0-9]" | cut -d " " -f 2)
    echo "Detected CUDA version: $CUDA_ARCH"
    
    # Determine appropriate architecture compute capability
    # Default to 5.0 (Maxwell) if can't determine
    COMPUTE_CAPABILITY="50"
    
    # Use make to build
    echo "Building GPU-ACS with make..."
    make
    
    # Check if build was successful
    if [ -f "gpuants" ]; then
      echo "GPU-ACS compiled successfully."
    else
      echo "GPU-ACS compilation failed. Check for errors."
    fi
    
    cd ..
  else
    echo "CUDA not detected. Skipping GPU-ACS compilation."
    echo "GPU-ACS requires CUDA 6.5 or newer and a CUDA-enabled GPU."
  fi
elif [ -f "GPUBasedACS-master/gpuants" ]; then
  echo "GPU-ACS executable already exists. Skipping compilation."
else
  echo "GPU-ACS source directory not found. Skipping compilation."
fi

# Build PIHC if source directory exists - following the README instructions with improved compilation
echo "Setting up PIHC..."
if [ -d "PIHC_TSP-master" ] && [ ! -f "PIHC_TSP-master/parallel/pihc" ]; then
  if command_exists nvcc; then
    cd PIHC_TSP-master/parallel
    
    # Check CUDA compute capability
    CUDA_COMPUTE_CAPABILITY=$(nvcc --version | grep -o "release [0-9]\+\.[0-9]" | cut -d " " -f 2)
    echo "Detected CUDA version: $CUDA_COMPUTE_CAPABILITY"
    
    # PIHC requires GPU with compute capability 3.5 or higher
    echo "Building PIHC using nvcc with sm_61 architecture..."
    # Using the command specified by the user
    nvcc PIHC.cu -arch=sm_61 -o pihc
    
    # Check if build was successful
    if [ -f "pihc" ]; then
      echo "PIHC compiled successfully."
    else
      echo "PIHC compilation failed. Check for errors."
      echo "Note: PIHC requires a GPU with compute capability 3.5 or higher."
      echo "Make sure you have the CUDA toolkit installed correctly."
    fi
    
    cd ../..
  else
    echo "CUDA not detected. Skipping PIHC compilation."
    echo "PIHC requires CUDA and a GPU with compute capability 3.5 or higher."
  fi
elif [ -f "PIHC_TSP-master/parallel/pihc" ]; then
  echo "PIHC executable already exists. Skipping compilation."
else
  echo "PIHC source directory not found. Skipping compilation."
fi

# PART 2: BUILD INSTANCE GENERATORS
echo "===================================================="
echo "  BUILDING INSTANCE GENERATORS"
echo "===================================================="

# Build TNM instance generator - compiles Tnm.cpp 
echo "Setting up TNM Instance Generator..."
if [ -d "hard_tsp_instantiation" ] && [ -f "hard_tsp_instantiation/Tnm.cpp" ] && [ ! -f "hard_tsp_instantiation/Tnm" ]; then
  cd hard_tsp_instantiation
  echo "Compiling TNM generator..."
  g++ -std=c++11 Tnm.cpp -o Tnm
  
  # Check if build was successful
  if [ -f "Tnm" ]; then
    echo "TNM instance generator compiled successfully."
  else
    echo "TNM instance generator compilation failed. Check for errors."
  fi
  cd ..
elif [ -f "hard_tsp_instantiation/Tnm" ]; then
  echo "TNM instance generator already exists. Skipping compilation."
else
  echo "TNM source file not found. Skipping compilation."
fi

# Build DIMACS generators using Makefile
echo "Setting up DIMACS Generators..."
if [ -d "DIMACS" ] && [ -f "DIMACS/Makefile" ]; then
  cd DIMACS
  
  # Check if any of the generators need to be built
  if [ ! -f "portgen" ] || [ ! -f "portcgen" ] || [ ! -f "portmgen" ]; then
    echo "Compiling DIMACS generators..."
    make
    
    # Check which generators were successfully built
    BUILT_TOOLS=""
    for tool in portgen portcgen portmgen; do
      if [ -f "$tool" ]; then
        BUILT_TOOLS="$BUILT_TOOLS $tool"
      fi
    done
    
    if [ -n "$BUILT_TOOLS" ]; then
      echo "Successfully built DIMACS generators:$BUILT_TOOLS"
    else
      echo "DIMACS generators compilation failed. Check for errors."
    fi
  else
    echo "All DIMACS generators already exist. Skipping compilation."
  fi
  cd ..
else
  echo "DIMACS directory or Makefile not found. Skipping compilation."
fi

# Make sure existing scripts are executable 
chmod +x scripts/*.sh 2>/dev/null
chmod +x *.sh 2>/dev/null

echo "===================================================="
echo "  Setup Complete!"
echo "===================================================="
echo ""
echo "SOLVERS:"
echo "1. Concorde: co031219/concorde/TSP/concorde"
echo "2. LKH: LKH-3.0.13/LKH"
echo "3. GPU-ACS: GPUBasedACS-master/gpuants" 
echo "4. PIHC: PIHC_TSP-master/parallel/pihc"
echo ""
echo "INSTANCE GENERATORS:"
echo "1. TNM: hard_tsp_instantiation/Tnm"
echo "2. DIMACS: DIMACS/portgen, DIMACS/portcgen, DIMACS/portmgen"
echo ""
echo "You can now add TSP instances to the benchmark folders and run tests."
echo ""
echo "Note: If some components were not compiled, make sure their"
echo "source files exist and all dependencies are installed."
echo "" 