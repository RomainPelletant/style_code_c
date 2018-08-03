#!/bin/bash

# clang_format.sh exit values
ESUCCESS=0
EREPLACE=1
EINVAL=3

# script location
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SCRIPT_FILE="$SCRIPT_DIR/../../clang_format.sh"

# log errors
# $1 error message
function elog () {
	# ANSI escape codes for colours
	local red='\033[0;31m'
	local nc='\033[0m'
	[[ $VERBOSE ]] && printf "${red}[failed]${nc}: %s\\n" "$1" >&2
}

# parse args
unset VERBOSE
while (( $# > 0 ))
do
	case "$1" in
	-v|--verbose)
		VERBOSE=true
		;;
	*)
		printf 'invalid argument [%s]\n' "$1"
		exit 1
		;;
	esac

	shift
done

# test if script returns invalid argument error on invalid arguments
"$SCRIPT_FILE" >/dev/null 2>&1
[[ $? != "$EINVAL" ]] && elog 'missing args' && exit 1

"$SCRIPT_FILE" -p "$SCRIPT_DIR/pass/**/*.{c,h}" >/dev/null 2>&1
[[ $? != "$EINVAL" ]] && elog 'no action was given' && exit 1

"$SCRIPT_FILE" noaction >/dev/null 2>&1
[[ $? != "$EINVAL" ]] && elog 'invalid action was given' && exit 1

"$SCRIPT_FILE" -p "$SCRIPT_DIR/**/*.{cpp,hpp}" check >/dev/null 2>&1
[[ $? != "$EINVAL" ]] && elog 'pattern should not result in targets' && exit 1

"$SCRIPT_FILE" -c non-existing-formatter check >/dev/null 2>&1
[[ $? != "$EINVAL" ]] && elog 'formatter should not be found' && exit 1

# test check functionality
"$SCRIPT_FILE" -p "$SCRIPT_DIR/pass/**/*.{c,h}" check >/dev/null 2>&1
[[ $? != "$ESUCCESS" ]] \
	&& elog 'pass example should not have returned an error' \
	&& exit 1

"$SCRIPT_FILE" -p "$SCRIPT_DIR/fail/**/*.{c,h}" check >/dev/null 2>&1
[[ $? != "$EREPLACE" ]] \
	&& elog 'fail example should have returned an error' \
	&& exit 1

"$SCRIPT_FILE" \
	-p "$SCRIPT_DIR/pass/**/*.{c,h}" \
	-p "\\$\\(echo '$SCRIPT_DIR/fail/src/main.c'\\)" \
	check >/dev/null 2>&1
[[ $? != "$EREPLACE" ]] \
	&& elog 'multiple patterns should contain a fail target' \
	&& exit 1

# test format functionality
fail_main="$SCRIPT_DIR/fail/src/main.c"
contents="$(cat "$fail_main")"
"$SCRIPT_FILE" -p "$SCRIPT_DIR/fail/src/main.c" format >/dev/null 2>&1
[[ $? != "$ESUCCESS" ]] \
	&& elog 'fail format example should have returned an error' \
	&& exit 1
rm "$fail_main" && echo "$contents" > "$fail_main"

exit 0
