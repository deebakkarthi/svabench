#!/usr/bin/env bash
prompt=$(<prompts/barebones.md)
rtl=$(<bench/comm/sockit_owm/rtl/sockit_owm.v)
prompt="${prompt/\{rtl\}/"$rtl"}"
echo "$prompt" | claude --model "haiku" -p --safe-mode --strict-mcp-config --tools ""\
       	--system-prompt "You are a helpful assistant."\
       	--no-session-persistence
