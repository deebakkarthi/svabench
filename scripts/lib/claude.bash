#!/usr/bin/env bash
# 
# Set of common functions involving claude




claude_infer () {
	# Disable this else claude will start incurring API costs
	unset ANTHROPIC_API_KEY
	# Use the second arg as the model
	if [[ ! -z "$2" ]]; then
		if [[ ! "$2" =~ ^(haiku|sonnet|opus|fable)$ ]]; then
			echo "$FUNCNAME: Invalid model name\nAllowed args: haiku|sonnet|opus|fable"
			exit 1
		fi
		model="$2"
	else
		# Use haiku by default
		model="haiku"
	fi
	echo "$1" | claude --print \
		--model $model \
		--safe-mode \
		--strict-mcp-config \
		--tools "" \
		--system-prompt "" \
		--no-chrome \
		--dangerously-skip-permissions \
		--no-session-persistence
}

_test () {
	[[ $(claude_infer "Say potato and only potato") = "potato" ]] &&\
	       	echo "claude_infer: PASSED" || echo "claude_infer: FAILED"
}

main () {
	_test
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	# This script is being run.
	__name__="__main__"
else
	# This script is being sourced.
	__name__="__source__"
fi

if [ "$__name__" = "__main__" ]; then
	main "$@"
fi

