#!/usr/bin/env bash
#
# Run jasper gold given a result dir

PROGNAME="$(basename "$0")"
usage() {
	cat<<-EOF
	Usage: $PROGNAME RESULT_DIR
	EOF
}

if [[ $# -ne 1 ]]; then
	>&2 usage
	exit 1
fi

mapfile -t benchmark_arr < <(find "$1" -type d -name sva -printf "%h\n" | sort)

for benchmark in "${benchmark_arr[@]}"; do
	# This will be used to call all the .tcl or .f files
	benchmark_prefix="$(basename "$benchmark")"
	pushd "$benchmark"
	jg -no_gui -tcl "$benchmark_prefix.tcl"
	popd
done
