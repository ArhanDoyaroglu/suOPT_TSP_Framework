#!/bin/bash


KNOWN_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_known_euc"
UNKNOWN_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_unknown_euc"
OUTPUT_DIR="/home/users/arhandoyaroglu/suOPT/outputs/gpuACS"
GPU_ANTS="/home/users/arhandoyaroglu/suOPT/GPUBasedACS-master/gpuants"

ALG="acs_gpu_alt"
ITER=1

# Create output directory if not exists
mkdir -p "$OUTPUT_DIR"

# Loop over both directories
for dir in "$KNOWN_DIR" "$UNKNOWN_DIR"; do
    for tspfile in "$dir"/*.tsp; do
        echo "Running instance: ${tspfile}"
        "$GPU_ANTS" --test "${tspfile}" \
                    --outdir "${OUTPUT_DIR}" \
                    --alg "${ALG}" \
                    --iter "${ITER}"
    done
done
