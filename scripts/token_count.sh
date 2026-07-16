#!/usr/bin/env bash
#
# Return the input token count for all the benchmarks

mapfile -t benchmark_arr < <(find bench/ -type d -name rtl -printf "%h\n")

echo "benchmark, tokens, words"
for benchmark in "${benchmark_arr[@]}"; do
	mapfile -t files_arr < <(find "$benchmark/rtl" -type f)
	num_tokens="$(./scripts/_token_count.py "${files_arr[@]}")"
	num_words=$"$(cat "${files_arr[@]}" | wc -w | awk '{$1=$1}1')"
	echo -e "$(basename "$benchmark"), $num_tokens, $num_words"
done
