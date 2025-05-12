import os
import math

def geo_to_euclidean(lat, lon):
    R = 6371  # Earth radius in km
    lat_rad = math.radians(lat)
    lon_rad = math.radians(lon)
    x = R * math.cos(lat_rad) * math.cos(lon_rad)
    y = R * math.cos(lat_rad) * math.sin(lon_rad)
    return f"{x:.6f}", f"{y:.6f}"

def fix_tsp_file(input_path, output_folder):
    with open(input_path, 'r') as file:
        lines = file.readlines()

    fixed_lines = []
    node_section = False

    for line in lines:
        line = line.strip()

        if line.startswith("DISPLAY_DATA_TYPE:"):
            continue  # Remove DISPLAY_DATA_TYPE line

        if line.startswith("EDGE_WEIGHT_TYPE:"):
            edge_weight_type = line.split(":")[-1].strip()
            if edge_weight_type != "GEO":
                return  # Skip non-GEO files
            fixed_lines.append("EDGE_WEIGHT_TYPE: EUC_2D")
            continue

        if line.startswith("NODE_COORD_SECTION"):
            node_section = True
            fixed_lines.append(line)
            continue

        if node_section:
            parts = line.split()
            if len(parts) == 3:
                node, lat, lon = parts
                x, y = geo_to_euclidean(float(lat), float(lon))
                fixed_lines.append(f"{node} {x} {y}")
                continue

        fixed_lines.append(line)

    if "EOF" not in fixed_lines:
        fixed_lines.append("EOF")

    fixed_filename = os.path.basename(input_path).replace(".tsp", "_geo2euc.tsp")
    output_path = os.path.join(output_folder, fixed_filename)

    with open(output_path, 'w', newline='\n') as file:
        file.write("\n".join(fixed_lines) + "\n")


def process_tsp_files(input_folders, output_folder):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for input_folder in input_folders:
        for filename in os.listdir(input_folder):
            if filename.endswith(".tsp"):
                input_path = os.path.join(input_folder, filename)
                fixed_filename = filename.replace(".tsp", "_fixed.tsp")
                output_path = os.path.join(output_folder, fixed_filename)

                if os.path.exists(output_path):
                    print(f"Skipping {filename} (already converted)")
                    continue

                print(f"Processing {filename}...")
                fix_tsp_file(input_path, output_folder)

    print("All GEO files processed.")


input_folders = [
    "/home/users/arhandoyaroglu/suOPT/benchmark/opt_known_noteuc"
]
output_folder = "/home/users/arhandoyaroglu/suOPT/benchmark/opt_known_euc"
process_tsp_files(input_folders, output_folder)
