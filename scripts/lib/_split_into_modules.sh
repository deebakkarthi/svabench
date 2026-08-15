#!/usr/bin/env bash
#
# Split a .sva file by module
# .sva (an extension I made up) contains assertions prefixed with
# `// module foo`
# A single .sva file can potentially contain multiple modules
# To ease postprocessing, this script splits that file into multiple ones
# based on the module

PROGNAME="$(basename "$0")"


usage() {
	cat<<-EOF
	Usage: $PROGNAME [-h | -d] FILE
	  FILE	the file to split
	  -d	delete the original file
	EOF
}

_D=false

while getopts 'hd' opt; do
	case "$opt" in
		h)
			usage
			exit 0
			;;
		d)
			_D=true
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

# Move to a tmp dir to prevent clogging up OG dir
tmp=$(mktemp -d)
pushd "$tmp" > /dev/null

csplit --silent --elide-empty-files $input_file '/^\/\/ module/' '{*}'
for f in *; do
	# Grab the module name from the first line of the file
	new_name="$(sed -n '1s/^\/\/ module //p' "$f").sv"
	# rename
	mv "$f" "$new_name"
	# Move to the OG dir
	mv "$new_name" "$(dirs +1)"
done

# Go back to OG dir
popd > /dev/null

# if -d delete OG file
if "$_D"; then
	rm $input_file
fi

# Cleanup
rm -rf "$tmp"
