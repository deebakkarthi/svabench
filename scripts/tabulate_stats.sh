#!/usr/bin/env bash

# Take in a results dir go through all the benchmarks and pretty print the
# stats


mapfile -t benchmark_arr < <(find "$1" -type d -name sva -printf "%h\n" | sort)

(
echo -ne "FILENAME\tDURATION\tITOKENS\tOTOKENS\n"
for benchmark in "${benchmark_arr[@]}";do
	jq -j 'keys[0], "\t", ([.[][]] | @tsv), "\n"' $benchmark/stats
done
) | column -t
