#!/usr/bin/env bash
#
# Run vppreproc on each benchmark and create a single file for each of them

mapfile -t benchmark_arr < <(find bench/ -type d -name rtl -printf "%h\n")

# Please call it from the root dir. I don't want to use git to traverse
# back and find the root dir
parent_dir=$(pwd)

# Create preproc dir if not present
if [[ ! -d $parent_dir/preproc ]];then
	mkdir -p "$parent_dir"/preproc
fi

for benchmark in "${benchmark_arr[@]}"; do
	if [[ ! -d "$parent_dir/preproc/${benchmark#*/}" ]]; then
		mkdir -p "$parent_dir/preproc/${benchmark#*/}/rtl"
	fi

	pushd "$benchmark" >/dev/null 2>&1 || exit
	vppreproc --noline --noblank --nocomment \
		-f "$(basename "$benchmark").f" \
		> "$parent_dir/preproc/${benchmark#*/}/rtl/$(basename "$benchmark").v"
	popd >/dev/null 2>&1 || exit
done
