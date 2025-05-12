#!/bin/bash
# Script to run TSP file format converters

echo "TSP Format Converter"
echo "===================="
echo "1. GEO → EUC_2D"
echo "2. EUC_2D → FULL_MATRIX"
echo "3. Run both conversions sequentially"
echo ""
read -p "Enter your choice (1/2/3): " choice

case "$choice" in
  1)
    read -p "Enter the path to the GEO TSP file: " tsp_file
    if [ -f "$tsp_file" ]; then
      python3 geo2euc_converter.py "$tsp_file"
    else
      echo "Error: File not found."
    fi
    ;;
  2)
    read -p "Enter the path to the EUC_2D TSP file: " tsp_file
    if [ -f "$tsp_file" ]; then
      python3 euc2fullmatrix_converter.py "$tsp_file"
    else
      echo "Error: File not found."
    fi
    ;;
  3)
    read -p "Enter the path to the GEO TSP file: " tsp_file
    if [ -f "$tsp_file" ]; then
      python3 geo2euc_converter.py "$tsp_file"
      euc_file="${tsp_file%.tsp}_euc.tsp"
      if [ -f "$euc_file" ]; then
        python3 euc2fullmatrix_converter.py "$euc_file"
      fi
    else
      echo "Error: File not found."
    fi
    ;;
  *)
    echo "Invalid choice."
    ;;
esac
