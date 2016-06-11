#!/bin/bash

set -e

# defaults
LIMIT=80
TAB_SIZE=8
unset EXCLUDE
unset TARGET

# print usage if no options
if [[ $# == 0 ]]
then
	printf "\
$0 [OPTION]... [TARGET]

	-l, --limit
		line limit in characters
		defaults to 80

	-t, --tab-size
		tab size in characters
		defaults to 8

	-e, --exclude
		posix extended regex expression\n"
	
	exit 1
fi

# parse options
while (( $# > 0 ))
do
	case "$1" in
	-l|--limit)
		LIMIT="$2"
		shift
		;;
	-t|--tab-size)
		TAB_SIZE="$2"
		shift
		;;
	-e|--exclude)
		EXCLUDE="$2"
		shift
		;;
	*)
		# target only allowed as final option
		[[ $# != 1 ]] && printf "invalid options\n" && exit 1
		TARGET="$1"
		;;
	esac

	shift
done

# verify options
[[ ! -e $TARGET ]] && printf "invalid target\n" && exit 1

# cd and unset failure var
cd "$TARGET"
unset FAIL

# loop over all files in path
while IFS= read -r -d '' file
do
	# check if file exceeds limit
	if [[ $(expand --tabs=$TAB_SIZE "$file" \
		| awk "{ if (length(\$0) > $LIMIT) print \"y\" }") ]]
	then
		FAIL=true
		printf 'FAIL '
	else
		printf 'PASS '
	fi
	printf "$file\n"
done \
	< <(find . \
	-regextype posix-extended \
	-type f \
	-not -regex "$EXCLUDE" \
	-exec grep -Iq . '{}' \; \
	-and -print0)

[[ $FAIL ]] && exit 1
exit 0
