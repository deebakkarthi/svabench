#!/usr/bin/env bash
#
# Prints "category/bench, num_files"

mapfile -t benchmark_arr < <(find bench/ -type d -name rtl -printf "%h\n" | sort)

echo "benchmark, files"
for benchmark in "${benchmark_arr[@]}"; do
	# Keep the files array around just in case
	# I know that I can find the count by piping find into wc
	# or using find itself. But the file names might be useful
	# in the future
	mapfile -t files_arr < <(find "$benchmark/rtl" -type f)
	num_files="${#files_arr[@]}"
	# Remove bench/ prefix
	echo -e "${benchmark#*/}, $num_files"
done
