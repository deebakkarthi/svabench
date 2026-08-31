#!/usr/bin/env bash
#
# Repeats small bench 5 times
# Passes along the options recieved
# Doesn't do any checking

PROGNAME="$(basename "$0")"


for _ in {1..5}; do
	./scripts/small_bench.sh $@
	# Exit if the first claude call fails
	if [[ $? != 0 ]];then
		exit $?
	fi
done
