#!/usr/bin/env bash
#
# Split a .sva file by module
# .sva (an extension I made up) contains assertions prefixed with
# `// module foo`
# A single .sva file can potentially contain multiple modules
# To ease postprocessing, this script splits that file into multiple ones
# based on the module

PROGNAME="$(basename "$0")"

_D=false
_V=false

log() {
	if [[ $_V = true ]]; then
		echo "$PROGNAME: [INFO] [$(date '+%Y-%m-%d %H:%M:%S')] $*"
	fi
}

usage() {
	cat<<-EOF
	Usage: $PROGNAME [-h | -d | -v] FILE
	  FILE	the file to split
	  -d	delete the original file
	  -v	verbose
	EOF
}


while getopts 'hdv' opt; do
	case "$opt" in
		h)
			usage
			exit 0
			;;
		d)
			_D=true
			;;
		v)
			_V=true
			;;
		*)
			>&2 usage
			exit 1
			;;
	esac
done

shift $((OPTIND - 1))

if [[ -z "$1" ]]; then
	>&2 echo -ne "$PROGNAME: FILE not provided\n"
	>&2 usage
	exit 1
fi

input_file=$1

if [[ ! -f "$input_file" ]]; then
	>&2 echo -ne "$PROGNAME: $input_file doesn't exist\n"
	exit 1
fi

input_file=$(realpath "$input_file")

log "$input_file exists"

# Move to a tmp dir to prevent clogging up OG dir
tmp=$(mktemp -d)
pushd "$tmp" > /dev/null

log "cd into $(pwd)"

csplit --silent --elide-empty-files $input_file '/^\/\/ module/' '{*}'
for f in *; do
	log "processing $f"
	# Grab the module name from the first line of the file
	new_name="$(sed -n '1s/^\/\/ module //p' "$f").sv"

	# Only move stuff if module name was found
	if [[ $new_name != ".sv" ]]; then
		# rename
		mv "$f" "$new_name"
		# dirs without -l returns with ~
		# ~ is expanded by the shell
		# When you just pass it to mv it doesn't understand it
		mv "$new_name" "$(dirs -l +1)"
	fi
done

# Go back to OG dir
popd > /dev/null

# if -d delete OG file
if "$_D"; then
	rm $input_file
fi

# Cleanup
rm -rf "$tmp"
