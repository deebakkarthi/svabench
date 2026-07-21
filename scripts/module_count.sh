#!/usr/bin/env bash
#
# Run `vhier` on each benchmark and print out the number of modules

mapfile -t benchmark_arr < <(find bench/ -type d -name rtl -printf "%h\n")

# Please call it from the root dir. I don't want to use git to traverse
# back and find the root dir
parent_dir=$(pwd)


echo "benchmark, modules"
for benchmark in "${benchmark_arr[@]}"; do
	pushd "$benchmark" >/dev/null 2>&1 || exit
	# Using v2k as `do` in hpdmc causes collision with SystemVerilog `do`
	# keyword. Alter this in the future if we add any SV projects
	num_modules=$(vhier --language 1364-2001 -f "$(basename $benchmark)".f --modules | wc -l)
	echo "${benchmark#*/}, $num_modules"
	popd >/dev/null 2>&1 || exit
done
