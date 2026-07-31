#!/usr/bin/env bash
# 
# Set of common functions involving claude

# args that cannot be changed by the user
readonly CLAUDE_DEFAULT_ARGS=(
--print
--safe-mode
--strict-mcp-config
--tools \"\"
--system-prompt \"\"
--no-chrome
--dangerously-skip-permissions
)

#######################################
# Runs claude with the necessary arguments
# to minimize context usage and mimic a
# plain API call as close as possible
#
# Arguments:
# 	- $1 prompt
#	- $2 model=haiku
#	- $3 uuid=None
#######################################
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

	# Make uuid optional so that I can use claude_infer in more places
	# If it was passed, then use that as the session-id
	if [[ ! -z "$3" ]]; then
		session="--session-id $3"
	fi


	echo "$1" | claude "${CLAUDE_DEFAULT_ARGS[@]}" \
		--model "$model" \
		"$session"
}

_test () {
	if [[ $(claude_infer "Say potato and only potato") = "potato" ]]; then
		echo "claude_infer: PASSED"
		exit 0
	else
		echo "claude_infer: FAILED"
		exit 1
	fi

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

