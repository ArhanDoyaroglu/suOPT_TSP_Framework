# TSP Solver Framework

## Description

This project is a framework to test and compare different solvers for the Traveling Salesman Problem (TSP). It helps generate test instances, convert input formats, run solvers (both CPU and GPU-based). It is designed for academic use and accessible to everyone in academia.

## Scripts

All necessary shell scripts for running solvers, generating instances, converting formats, and cleaning up are stored in the `scripts/` folder. Solver runners include those for:
- Concorde (exact solver)
- LKH (heuristic solver)
- GPU-based ACS (Ant Colony System)
- GPU PIHC (Parallel Iterated Hill Climbing)

Instance generators include scripts for DIMACS-style and Hougardy-Zhong (Tnm) instances. 
There are also Python-based converters to convert GEO to EUC_2D and EUC_2D to FULL_MATRIX.
Cleanup scripts are provided to delete generated solutions or test sets.

## Converters

GEO to EUC_2D conversion is required for GPU solvers like ACS and PIHC. These solvers only accept Euclidean coordinates, so any TSP file with GEO format must be converted before use. The converter `geo2euc_converter.py` handles this task, and is typically run through a script that allows you to choose the type of conversion.

Some solvers or tools may require a full distance matrix rather than coordinates. In such cases, EUC_2D files can be converted to FULL_MATRIX format using `euc2fullmatrix_converter.py`.

To streamline usage, there is a unified script that prompts the user to select one of the following options:
1. GEO → EUC_2D
2. EUC_2D → FULL_MATRIX
3. Run both conversions sequentially

This is handled via `run_converters.sh`, which calls the relevant Python converters.

## Generators

The framework has two types of instance generators:

1. **DIMACS Generator**: `generate_dimacs_instances.sh` produces random TSP instances based on the DIMACS challenge format. These are useful for testing general performance.

2. **Tnm Generator**: `generate_tnm_instances.sh` produces hard-to-solve TSP instances following the Tnm model described by Hougardy and Zhong. These are valuable for stress testing solvers.

Both instance types are saved in the appropriate benchmark folders and can be removed using their respective delete scripts.

## Solvers

### Concorde
An exact solver that can process both GEO and EUC_2D instances. It outputs solution files (`.sol`) and moves them into a cleaned `tours/concorde_tours` directory. Temporary files are automatically deleted.

### LKH
A heuristic solver that can support multiple salesmen (mTSP). It accepts known or unknown instances in any format. Users can specify strategies in the `.par` file. It outputs `.tour` files and logs.

### GPU ACS
Uses a parallel version of Ant Colony System. It only accepts EUC_2D files. Before using this solver, ensure GEO files are converted. Outputs are saved in JSON format.

### GPU PIHC
A CUDA-based heuristic. It requires the user to select both an initialization strategy and a CUDA thread mapping style. Like ACS, it only accepts EUC_2D input files and produces `.sol` output files.

## Usage

Before running any solver, make sure to read the README of that solver and generator, then compile or configure it if necessary. Run the setup script to compile and configure all solvers:

```bash
./setup_framework.sh
```

Then, generate test instances using the provided generator scripts:

```bash
./scripts/generate_dimacs_instances.sh
./scripts/generate_tnm_instances.sh
```

You can also add your own TSP instances to the benchmark folders. Just make sure they follow the correct TSPLIB format and are placed in the right directories (e.g., opt_known_euc or opt_unknown_euc).

Convert any GEO files to EUC_2D using the appropriate converter:

```bash
./scripts/run_converters.sh
```

Once data is ready, you can run all solvers on all instances with:

```bash
./run_all_solvers.sh
```

Or interactively select which instances to run:

```bash
./run_all_solvers.sh single
```

After running, use the cleanup script to delete intermediate and solution files:

```bash
./cleanup_all_solver_outputs.sh
```

To uninstall compiled executables while preserving source code:

```bash
./uninstall_framework.sh
```

## Requirements

- GCC/G++ compiler
- CUDA toolkit (for GPU solvers)
- Python 3 (for converters)
- QSopt library (for Concorde)
- Basic Linux utilities (bash, make, etc.)

## Structure

- `benchmark/`: Contains TSP instance files
- `scripts/`: Contains all runner and converter scripts
- `outputs/`: Stores solver outputs (created during execution)
- `tours/`: Stores optimal tours
- `temp/`: Temporary directory for intermediate files
- `results_all_solvers/`: Contains summary results from all solver runs

## License

This software is provided for academic use only. 