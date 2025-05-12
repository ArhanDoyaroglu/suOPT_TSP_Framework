#!/bin/bash

OUTPUT_DIR="/home/users/arhandoyaroglu/suOPT/benchmark/opt_unknown_euc"
PORTGEN_EXEC="/home/users/arhandoyaroglu/suOPT/DIMACS/portgen"

# Set dimension range
MIN_DIM=1000
MAX_DIM=10000

# Ask user how many instances to generate
read -p "How many TSP instances do you want to generate? " NUM_INSTANCES

mkdir -p "$OUTPUT_DIR"

# Generate instances with random dimension between MIN_DIM and MAX_DIM
for ((i = 1; i <= NUM_INSTANCES; i++)); do
    DIM=$((RANDOM % (MAX_DIM - MIN_DIM + 1) + MIN_DIM))
    "$PORTGEN_EXEC" "$DIM" $((1 + i)) > "$OUTPUT_DIR/E1k_$i.tsp"
    echo "Generated: $OUTPUT_DIR/E1k_$i.tsp with dimension $DIM"
done

echo "$NUM_INSTANCES TSP instances generated in: $OUTPUT_DIR"