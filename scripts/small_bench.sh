#!/usr/bin/env bash
#
# small_bench is a benchmark with just sockit_owm, sha3
# It is intended to help with writing the benchmark itself and not indicative
# of the performance of the model
#
# RATIONALE BEHIND THE BENCHMARKS CHOSEN
# --------------------------------------
# I want this to be really small. This allows me to test the harness without
# worry about cost. I want the test to actually call claude, so this really
# matters
# sockit_owm is the smallest but it is a single file and has a single module
#
# sha3 is the next smallest. It has multiple files ergo multiple modules
#
# I have multiplicty of benchmarks as well as files. So the full benchmark
# will just have a larger starting array and nothing more

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/lib/claude.bash"

# These are the ids of the benchmarks
# I need the categories in addition to the name in order to retrive them
# Idk if this look ugly or not but right now I do require the category
benchmarks=('comm/sockit_owm' 'crypto/sha3')
result_dir="results/$(date +"%Y%m%dT%H%M%S")"
mkdir -p "$result_dir"

# This is the loop to iterate over the benchmarks
for benchmark in "${benchmarks[@]}"; do
	sva_dir="$result_dir/$benchmark/sva"
	mkdir -p "$sva_dir"
	# You have to then iterate over all the rtl files
	for file in bench/"$benchmark"/rtl/*; do
		# Prompt preparation
		prompt=$(<prompts/barebones.md)
		rtl=$(<$(realpath $file))
		prompt="${prompt/\{rtl\}/"$rtl"}"

		# path to store the output assertions
		# Replace file extension with .sva
		output_file="$sva_dir/$(basename $file | sed 's/\.[^.]*$//').sva"

		claude_infer "$prompt" > "$output_file"

		# Sometimes backtick can be present
		./scripts/_rm_fenced_code_blocks.sh "$output_file"
	done
done
