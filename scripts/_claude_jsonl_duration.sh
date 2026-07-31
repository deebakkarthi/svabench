#!/usr/bin/env bash
#
# Calculate duration_s of a claude session from a .jsonl file

PROGNAME=$(basename $0)

usage () {
	cat <<-EOF
	Usage: $PROGNAME [FILE | -h]
	Calculate duration in ms of a claude session
	 -h	Help
	 FILE	.jsonl file to read

	 If FILE is not provided STDIN is read
	EOF
}


if [[ ! -z "$1" ]]; then
	if [[ "$1" = "-h" ]];then
		usage
		exit 0
	else
		input_file="$1"
	fi
else
	input_file="/dev/stdin"
fi


# Have to use date because jq strptime cannot handle fractional seconds
# '+%s' converts to UNIX timestamp
# TODO: milliseconds?
# date +%N gives nanoseconds but is not as portable
# If the difference is in milliseconds do I really care?
# Most of my sessions are pretty long anyway
jq -M -S '.timestamp | select(. != null)' "$input_file" | \
       	xargs -L1 date "+%s" -d | \
	jq -M -s '{duration:(max - min)}'
