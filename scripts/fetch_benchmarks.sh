#!/usr/bin/env bash
#
# Script to fetch the RTL files from svabench_test_designs
# and remove extraneous stuff

rm -rf bench/
git clone --depth=1 https://github.com/deebakkarthi/svabench_test_designs bench
# Remove all the folders except bench/
find bench/ -depth -maxdepth 1  -type d ! -name bench -exec rm -rf {} \;
# Remove all the files
find bench/ -depth -maxdepth 1  -type f -exec rm -rf {} \;
# Move everything to the parent dir
mv bench/bench/* bench/
rm -rf bench/bench
