#!/usr/bin/env bash
#
# Return the token counts of the preprocessed files

mapfile -t file_arr < <(find preproc/ -type f -name '*.v')

echo "benchmark, tokens, words"
for file in "${file_arr[@]}"; do
	num_tokens=$(scripts/_token_count.py "$file")
	num_words=$(cat "$file" | wc -w | awk '{$1=$1}1')
	echo "$(basename "$file"), $num_tokens, $num_words"
done
