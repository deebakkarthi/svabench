#!/usr/bin/env bash
# 
# Set of utility functions common to SVABENCH

#######################################
# Log a message
# Globals:
#   _V
# Arguments:
#   $1 - Message to be logged
#   $2 - Level. Defaults to INFO
#######################################

dbk_log() {
	if [[ $_V = true ]]; then
		echo "$PROGNAME: [${2:-INFO}] [$(date '+%Y-%m-%d %H:%M:%S')] $1"
	fi
}
