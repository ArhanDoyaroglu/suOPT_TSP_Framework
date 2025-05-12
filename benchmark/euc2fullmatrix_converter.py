import os
import math

def parse_euc2d_tsp(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    name = ""
    dimension = 0
    coords = []
    in_coords = False

    for line in lines:
        line = line.strip()
        if line.startswith("NAME"):
            name = line.split(":")[-1].strip()
        elif line.startswith("DIMENSION"):
            dimension = int(line.split(":")[-1].strip())
        elif line.startswith("NODE_COORD_SECTION"):
            in_coords = True
            continue
        elif line == "EOF":
            break

        if in_coords:
            parts = line.split()
            if len(parts) == 3:
                _, x, y = parts
                coords.append((float(x), float(y)))

    return name, dimension, coords

def compute_distance_matrix(coords):
    n = len(coords)
    matrix = [[0] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            xi, yi = coords[i]
            xj, yj = coords[j]
            dist = math.sqrt((xi - xj) ** 2 + (yi - yj) ** 2)
            matrix[i][j] = round(dist)
    return matrix

def write_full_matrix_tsp(name, matrix, output_path):
    with open(output_path, 'w') as f:
        f.write(f"NAME: {name}_fullmatrix\n")
        f.write("TYPE: TSP\n")
        f.write("COMMENT: Converted from EUC_2D to FULL_MATRIX\n")
        f.write(f"DIMENSION: {len(matrix)}\n")
        f.write("EDGE_WEIGHT_TYPE: EXPLICIT\n")
        f.write("EDGE_WEIGHT_FORMAT: FULL_MATRIX\n")
        f.write("EDGE_WEIGHT_SECTION\n")
        for row in matrix:
            line = " ".join(f"{val:3}" for val in row)
            f.write(f" {line}\n")
        f.write("EOF\n")

def convert_euc2d_to_full_matrix(filepath):
    output_folder = "/home/users/arhandoyaroglu/suOPT/euc_to_matrix/"
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    name, dimension, coords = parse_euc2d_tsp(filepath)
    matrix = compute_distance_matrix(coords)
    output_filename = os.path.join(output_folder, f"{name}_euc2fullmatrix.tsp")
    write_full_matrix_tsp(name, matrix, output_filename)
    print(f"Converted {name} to FULL_MATRIX: {output_filename}")

# Batch conversion from both directories
input_dirs = [
    "/home/users/arhandoyaroglu/suOPT/benchmark/opt_known_euc",
    "/home/users/arhandoyaroglu/suOPT/benchmark/opt_unknown_euc"
]

for dir_path in input_dirs:
    for filename in os.listdir(dir_path):
        if filename.endswith(".tsp"):
            full_path = os.path.join(dir_path, filename)
            convert_euc2d_to_full_matrix(full_path)
