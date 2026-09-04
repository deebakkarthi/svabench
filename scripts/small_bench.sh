#!/usr/bin/env bash
#
# small_bench is a benchmark with just sockit_owm, sha3
# It is intended to help with writing the benchmark itself and not indicative
# of the performance of the model
#
# RATIONALE BEHIND THE BENCHMARKS CHOSEN
# --------------------------------------
# I want this to be really small. This allows me to test the harness without
# worrying about cost. I want the test to actually call claude, so this really
# matters
# sockit_owm is the smallest but it is a single file and has a single module
#
# sha3 is the next smallest. It has multiple files ergo multiple modules
#
# I have multiplicty of benchmarks as well as files. So the full benchmark
# will just have a larger starting array and nothing more

PROGNAME="$(basename $0)"

export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/lib/claude.bash"
. "$SCRIPT_DIR/lib/utils.bash"

# Defaults
MODEL=haiku
PROMPT_FILE="prompts/barebones.txt"

usage() {
	cat<<-EOF
	Usage: $PROGNAME [-h] [-m MODEL] [-p PROMPT_FILE] [-v]
	  -h			Print out this help message
	  -m MODEL		The model to be used. The default model is haiku
	  -p PROMPT_FILE	The file to use as the prompt. Default is prompts/barebones.txt
	  -v			Verbose
	EOF
}

while getopts 'vhm:p:' opts; do
	case $opts in
		v)
			_V=true
			;;
		h)
			usage
			exit 0
			;;
		m)
			# Check if model is valid
			if [[ ! "$OPTARG" =~ ^(haiku|sonnet|opus|fable)$ ]]; then
				>&2 echo -ne "$PROGNAME: "$OPTARG" is an invalid model name\nAllowed args: haiku|sonnet|opus|fable\n"
				exit 1
			fi

			MODEL="$OPTARG"
			dbk_log "Changing model to $MODEL"
			;;
		p)
			if [[ ! -f "$OPTARG" ]]; then
				>&2 echo -ne "$PROGNAME: $OPTARG doesn't exist"
				exit 1
			fi

			PROMPT_FILE="$OPTARG"
			dbk_log "Changing log file to $PROMPT_FILE"
			;;
		*)
			>&2 usage
			exit 1
			;;
	esac

done

# Check if we are actually logged in before executing
# It is easier to check this than check the output and see if
# "OAuth expired: ..." being written to the file. I also don't know if
# claude will output an exit code of 1 if that happens
# But the below function is guaranteed to exit with 1 if not logged in
# TODO: This just shows if logged it and not actually working
# you can be logged in and not be able to prompt without relogging
if ! claude_logged_in ; then
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
	dbk_log "Processing $benchmark"
	sva_dir="$result_dir/$benchmark/sva"
	mkdir -p "$sva_dir"
	# You have to then iterate over all the rtl files
	for file in bench/"$benchmark"/rtl/*; do

		dbk_log "\tProcessing $benchmark->$file"

		# Prompt preparation
		# Pass in debug prompt as an opt-arg
		prompt=$(<"$PROMPT_FILE")
		rtl=$(<$(realpath $file))
		prompt="${prompt/\{rtl\}/"$rtl"}"

		echo "$prompt" > "$result_dir/$benchmark/prompt"

		# path to store the output assertions
		# Replace file extension with .sva
		output_file="$sva_dir/$(basename $file | sed 's/\.[^.]*$//').sva"

		session_id=$(uuidgen)
		project_dir="$(claude_project_dir "$(pwd)")"

		# Delete stuff not to pollute the context
		claude_cleanup "$(pwd)"

		claude_infer "$prompt" "$MODEL" "$session_id" > "$output_file"

		session_file="$project_dir/$session_id.jsonl"

		duration=$(./scripts/_claude_jsonl_duration.sh "$session_file")
		claude_usage=$(./scripts/_claude_jsonl_usage.sh "$session_file")
		echo $duration $claude_usage | jq -c -s "{\"$(basename $file)\": (add)}" >> "$result_dir/$benchmark/stats"
		dbk_log "Claude took $duration and used $claude_usage"

		# Cleanup up after oneself
		claude_cleanup "$(pwd)"
	done
done
