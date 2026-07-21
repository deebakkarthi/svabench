#!/usr/bin/env bash
#
# Return the input token count for all the benchmarks

mapfile -t benchmark_arr < <(find bench/ -type d -name rtl -printf "%h\n" | sort)

for benchmark in "${benchmark_arr[@]}"; do
	mapfile -t files_arr < <(find "$benchmark/rtl" -type f)
	num_tokens="$(cat "${files_arr[@]}" | wc -w | awk '{$1=$1};1')"
	# Remove bench/ prefix
	echo -e "${benchmark#*/}, $num_tokens"
done
