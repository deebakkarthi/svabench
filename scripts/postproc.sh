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

# Need this to access scripts after cd-ing into different dirs
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

usage() {
	echo -ne "Usage: $PROGNAME [-h] DIR\n"
}

if [[ -z "$1" ]]; then
	>&2 usage
	exit 1
else
	if [[ $1 = "-h" ]];then
		usage
		exit 0
	else
		results_dir=$1
	fi
fi

# Make sure folder exists
if [[ ! -d "$results_dir" ]]; then
	echo -ne "$PROGNAME: $results_dir doesn't exit\n"
	exit 1
fi

# Find all the sva/ directories and print its parent's path (%h)
mapfile -t benchmark_arr < <(find "$results_dir" -type d -name sva -printf "%h\n" | sort)

echo "${benchmark_arr[@]}"

# Loop over the BENCHMARKS
for benchmark in "${benchmark_arr[@]}"; do

	# cd into that dir so that new files are placed correctly
	pushd $benchmark/sva > /dev/null

	# Loop over the FILES
	# Each benchmark might have multiple .sva files
	# The previous step should ONLY produce .sva files as we are
	# specifically looking for those here.
	for file in *; do
		echo $file
		# Remove backticks
		$SCRIPT_DIR/_rm_fenced_code_blocks.sh "$file"

		$SCRIPT_DIR/lib/_split_into_modules.sh "$file"
	done

	popd > /dev/null
done
