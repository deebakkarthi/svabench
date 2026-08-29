#!/usr/bin/env bash

PROGNAME="$(basename "$0")"

usage() {
	cat<<-EOF
	Usage: $PROGNAME DIR

	Output a Verilog command file with all the files under DIR
	The paths are all relative from the $PWD
	EOF
}

if [[ "$#" -lt 1 ]]; then
	usage
	exit 1
fi

input_dir="$1"

# Check dir exists
if [ ! -d "$input_dir" ]; then
	echo "$progname: $input_dir doesn't exist"
	exit 1
fi

find $input_dir \( -name '*.v' -o -name '*.sv' -o -name '*.sva' \) -printf "%p\n"
exit $?
