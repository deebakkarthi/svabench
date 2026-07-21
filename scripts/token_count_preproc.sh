#!/usr/bin/env bash
#
# Return the token counts of the preprocessed files

mapfile -t benchmark_arr < <(find preproc/ -type d -name rtl -printf "%h\n" | sort)

echo "benchmark, tokens"
for benchmark in "${benchmark_arr[@]}"; do
	mapfile -t files_arr < <(find "$benchmark/rtl" -type f)
	num_tokens="$(./scripts/_token_count.py "${files_arr[@]}")"
	echo -e "${benchmark#*/}, $num_tokens"
done
