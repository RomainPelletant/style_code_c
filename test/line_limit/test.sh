#!/bin/bash

function msg_v()
{
	[[ $VERBOSE ]] && printf '%s\n' "$1"
}

unset VERBOSE
[[ "$1" == '-v' || "$1" == '--verbose' ]] && VERBOSE=true

TARGET='pass'
TMP="$(../../line_limit.sh -v -i "$TARGET")"
msg_v "$TMP"
if [[ $(echo "$TMP" | grep -Ev '^[A-Z]+ +PASS ') ]]
then
	echo "test for '$TARGET' failed"
	exit 1
fi
msg_v "test for '$TARGET' passed"

TARGET='fail/limit'
TMP="$(../../line_limit.sh -v "$TARGET")"
msg_v "$TMP"
if [[ $(echo "$TMP" | grep -Ev 'LIMIT +FAIL ') ]]
then
	echo "test for '$TARGET' failed"
	exit 1
fi
msg_v "test for '$TARGET' passed"

TARGET='fail/indent'
TMP="$(../../line_limit.sh -v -i "$TARGET")"
msg_v "$TMP"
if [[ $(echo "$TMP" | grep -Ev '^(LIMIT .*|INDENT +FAIL) ') ]]
then
	echo "test for '$TARGET' failed"
	exit 1
fi
msg_v "test for '$TARGET' passed"

exit 0
