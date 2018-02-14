#!/bin/bash

function msg_v()
{
	[[ ! $1 ]] && return 0
	[[ $VERBOSE ]] && printf '%s\n' "$1"
}

unset VERBOSE
[[ "$1" == '-v' || "$1" == '--verbose' ]] && VERBOSE=true

TARGET='pass'
TMP="$(../../line_limit.sh -v -i "$TARGET")"
msg_v "$TMP"
if [[ $(echo "$TMP" | grep -E "^$TARGET") ]]
then
	echo "test for '$TARGET' failed"
	echo "expected NO matches"
	exit 1
fi
msg_v "test for '$TARGET' passed"

for TARGET in 'fail/limit' 'fail/indent'
do
	TMP="$(../../line_limit.sh -v -i "$TARGET")"
	msg_v "$TMP"
	for FILE in "$TARGET/"*
	do
		if [[ ! $(echo "$TMP" | grep -E "^$(basename "$FILE")") ]]
		then
			echo "test for '$TARGET' failed"
			echo "expected '$FILE' to fail, but it passed"
			exit 1
		fi
	done
	msg_v "test for '$TARGET' passed"
done

exit 0
