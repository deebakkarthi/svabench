#!/usr/bin/env bash
#
# Given a `results_dir` this iterates over the benchmarks and places the
# appropriate rtl and jasper files

PROGNAME="$(basename "$1")"
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
	# Get the category suffix <category>/<benchmark_name>
	category=$(truncate_path_to_bench $benchmark)
	# Copy from bench/
	cp --recursive -f bench/$category/* $benchmark
done
