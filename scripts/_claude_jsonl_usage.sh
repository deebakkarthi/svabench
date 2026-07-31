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


# First we slurp all the JSONL objects into a single array
# Only then can we perform unique_by
# After that we explode them back using .[]
# This allows us to aggregate within each entry
# I don't know how to put them back into a single array again
# So doing the easy thing of just piping it to another jq instance and
# slurpping
#
# The second jq operates on a single array
# It uses map() to essentially produce another array with just the selected
# field and pipes it to add to aggregate
jq -M 'select(.type == "assistant")' "$input_file" \
	| jq -M -s 'unique_by(.requestId)
		| .[]
	       	| {input_tokens:
	       		(.message.usage.input_tokens
			+.message.usage.cache_creation_input_tokens
			+.message.usage.cache_read_input_tokens),
		   output_tokens: .message.usage.output_tokens
	   	  }' \
	| jq -M -s '{input_tokens: (map(.input_tokens)|add),
		  output_tokens: (map(.output_tokens)|add)}'
