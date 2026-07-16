#!/usr/bin/env bash
# Run vppreproc on each benchmark and create a single file for each of them
#
mapfile -t benchmark_arr < <(find bench/ -type d -name rtl -printf "%h\n")

parent_dir=$(pwd)
for benchmark in "${benchmark_arr[@]}"; do
	pushd "$benchmark" >/dev/null 2>&1 || exit
	vppreproc --noline --noblank --nocomment \
		-f "$(basename "$benchmark").f" \
		> "$parent_dir/preproc/$(basename "$benchmark").v"
	popd >/dev/null 2>&1 || exit
done
