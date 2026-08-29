#!/usr/bin/env bash
#
# Given a `results_dir` this iterates over the benchmarks and places the
# appropriate rtl and jasper files

PROGNAME="$(basename "$1")"

# Need this to access scripts after cd-ing into different dirs
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

usage() {
	cat<<-EOF
	Usage: $PROGNAME RESULT_DIR
	EOF
}

truncate_path_to_bench() {
	penultimate="$(dirname "$1")"
	echo "$(basename "$penultimate")/$(basename $1)"
}

if [[ $# -ne 1 ]]; then
	>&2 usage
	exit 1
fi

mapfile -t benchmark_arr < <(find "$1" -type d -name sva -printf "%h\n" | sort)

for benchmark in "${benchmark_arr[@]}"; do
	benchmark_prefix="$(basename "$benchmark")"
	
	# Get the category suffix <category>/<benchmark_name>
	category=$(truncate_path_to_bench $benchmark)
	# Copy from bench/
	cp --recursive -f bench/$category/* $benchmark

	# cd in the dir for relative paths
	pushd $benchmark
	$SCRIPT_DIR/gen_command_file.sh ./sva > "$benchmark_prefix"_sva.f
	popd
done
