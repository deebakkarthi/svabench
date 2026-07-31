#!/usr/bin/env bash
# 
# Removes ``` lines in a file

PROGNAME="$(basename "$0")"

usage () {
	echo -e "Usage: $PROGNAME FILE\n  FILE\tfile to remove backticks from"
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

sed -i '/^```/d' "$1"
