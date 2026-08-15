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

PROGNAME="$(basename $0)"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/lib/claude.bash"

# Check if we are actually logged in before executing
# It is easier to check this than check the output and see if
# "OAuth expired: ..." being written to the file. I also don't know if
# claude will output an exit code of 1 if that happens
# But the below function is guaranteed to exit with 1 if not logged in
if [[ ! claude_logged_in ]]; then
	echo "$PROGNAME: Claude not logged in"
	exit 1
fi

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
		# If DEBUG is not defined
		if [[ -z $DEBUG ]]; then
			model="haiku"

			# Prompt preparation
			prompt=$(<prompts/barebones.md)
			rtl=$(<$(realpath $file))
			prompt="${prompt/\{rtl\}/"$rtl"}"
		else
			# Always use haiku for debugging
			# I know that haiku is also used above but that may
			# change. DONT change this. I cannot use readonly
			# for some reason
			model="haiku"
			prompt="Say Potato and only potato"
		fi

		# path to store the output assertions
		# Replace file extension with .sva
		output_file="$sva_dir/$(basename $file | sed 's/\.[^.]*$//').sva"

		session_id=$(uuidgen)
		project_dir="$(claude_project_dir "$(pwd)")"

		# Delete stuff not to pollute the context
		claude_cleanup "$(pwd)"

		claude_infer "$prompt" "$model" "$session_id" > "$output_file"

		session_file="$project_dir/$session_id.jsonl"

		duration=$(./scripts/_claude_jsonl_duration.sh "$session_file")
		usage=$(./scripts/_claude_jsonl_usage.sh "$session_file")
		echo $duration $usage | jq -c -s "{\"$(basename $file)\": (add)}" >> "$result_dir/$benchmark/stats"

		# Cleanup up after oneself
		claude_cleanup "$(pwd)"
	done
done
