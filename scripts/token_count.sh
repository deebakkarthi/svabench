#!/usr/bin/env bash
#
# Return the input token count for all the benchmarks

mapfile -t benchmark_arr < <(find bench/ -type d -name rtl -printf "%h\n")

for benchmark in "${benchmark_arr[@]}"; do
	mapfile -t files_arr < <(find "$benchmark/rtl" -type f)
	num_tokens="$(./scripts/_token_count.py "${files_arr[@]}")"
	echo -e "$benchmark, $num_tokens"
done
