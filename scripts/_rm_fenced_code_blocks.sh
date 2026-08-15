#!/usr/bin/env bash
# 
# Removes ``` lines in a file

PROGNAME="$(basename "$0")"

usage () {
	cat<<-EOF
	Usage: $PROGNAME FILE
	  FILE	file to remove backticks from

	$PROGNAME alters FILE inplace
	EOF
}

if [[ $# -ne 1 ]]; then
	usage
	exit 1
fi

# Check if file exists
if [[ ! -f "$1" ]]; then
	echo "$PROGNAME: $1 doesn't exist"
	exit 1
fi

# Make it portable instead of -i
sed '/^```/d' "$1" > "$1".$$
mv "$1".$$ "$1"
