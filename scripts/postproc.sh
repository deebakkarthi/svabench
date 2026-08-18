#!/usr/bin/env bash
#
# Postprocess a results dir
# Postprocess includes
# 	- removing backticks
# 	- splitting into modules
# 	- creating assert modules
# 	- bind them
# 	- Create command files

PROGNAME="$(basename "$0")"

log() {
	if [[ $_V = true ]]; then
		echo "$PROGNAME: [INFO] [$(date '+%Y-%m-%d %H:%M:%S')] $*"
	fi
}


_V=false

# Need this to access scripts after cd-ing into different dirs
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

usage() {
	echo -ne "Usage: $PROGNAME [-h | -v] DIR\n"
}

while getopts 'hv' opt; do
	case "$opt" in
		h)
			usage
			exit 0
			;;
		v)
			_V=true
			;;
		*)
			>&2 usage
			exit 1
			;;
	esac
done

shift $((OPTIND -1))

if [[ -z "$1" ]]; then
	>&2 echo "$PROGNAME: DIR not provided"
	>&2 usage
	exit 1
fi

results_dir=$1

# Make sure folder exists
if [[ ! -d "$results_dir" ]]; then
	echo -ne "$PROGNAME: $results_dir doesn't exit\n"
	exit 1
fi

log "$results_dir exists"

# Find all the sva/ directories and print its parent's path (%h)
mapfile -t benchmark_arr < <(find "$results_dir" -type d -name sva -printf "%h\n" | sort)

log "The benchmarks are ${benchmark_arr[@]}"

# Loop over the BENCHMARKS
for benchmark in "${benchmark_arr[@]}"; do

	# cd into that dir so that new files are placed correctly
	pushd $benchmark/sva > /dev/null
	log "cd into $(pwd)"

	# Loop over the FILES
	# Each benchmark might have multiple .sva files
	# The previous step should ONLY produce .sva files as we are
	# specifically looking for those here.
	for file in *.sva; do
		log "Processing $file"

		# Remove backticks
		$SCRIPT_DIR/_rm_fenced_code_blocks.sh "$file"

		# Split each .sva file into potentially multiple .sv files
		# This will also delete the .sva file
		$SCRIPT_DIR/lib/_split_into_modules.sh -d "$file"
	done
	# Loop over each .sv file and run assert_decl_from_sva
	# Doing this separately as we don't know how many .sv files will
	# be created. If you do it above then you will run assert_decl_from_sva
	# on the same file multiple times
	find . -name "*.sv" -exec\
		bash -c 'assert_decl_from_sva -m "$(basename {} | sed 's/\.[^.]*$//')" -f {} | sponge {}' \;

	popd > /dev/null
	log "cd back into $(pwd)"
done
