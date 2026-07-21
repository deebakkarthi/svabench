#!/usr/bin/env bash

join_rec() {
	f1=$1
	f2=$2
	shift 2
	if [ $# -gt 0 ]; then
		join -t, "$f1" "$f2" | join_rec - "$@"
	else
		join -t, "$f1" "$f2"
	fi
}

join_rec $(find artifacts/ -type f\
       	-name *.csv\
       	! -name comparison.csv | xargs) | column -t
