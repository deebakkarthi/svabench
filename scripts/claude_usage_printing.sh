#!/usr/bin/env bash

unset ANTHROPIC_API_KEY
# Claude uses the following format:
# 	~/.claude/projects/<sanitized-cwd>/<session-id>.jsonl
# 	Using the exact logic as CC [src/utils/sessionStoragePortable.ts:311]
project_dir="$HOME/.claude/projects/$(realpath . | sed 's/[^a-zA-Z0-9]/-/g')"
# Remove all the previous jsonl files
rm -rf $project_dir/*

# Set a custom session id so that we can retrieve it later
uuid=$(uuidgen)
echo "say potato and only potato" | claude --print \
	--model "haiku" \
	--safe-mode \
	--strict-mcp-config \
	--tools "" \
	--system-prompt "" \
	--no-chrome \
	--dangerously-skip-permissions \
	--session-id "$uuid"

session_file="$project_dir/$uuid.jsonl"

./scripts/_claude_jsonl_duration.sh "$session_file"
./scripts/_claude_jsonl_usage.sh "$session_file"

# Cleanup
rm -rf "$session_file"
rm -rf $project_dir/*
