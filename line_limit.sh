#!/bin/bash

set -e

# defaults
LIMIT=80
TAB_SIZE=8
unset EXCLUDE
unset GIT
unset SUBMODULES
unset VERBOSE
unset QUIET
unset TARGET

# constants
readonly CMD="$0"

# functions
function print_help()
{
	printf '%s\n' "\
$CMD [OPTION]... [TARGET]

	-l, --limit <limit>
		line limit in characters
		defaults to 80

	-t, --tab-size <size>
		tab size in characters
		defaults to 8

	-e, --exclude <expr>
		posix extended regex expression

	-g, --git
		also check the .git folder
		defaults to ignoring all .git folders

	-s, --submodules
		also check git submodules
		defaults to parsing \$PWD/.gitmodules
		and excluding all paths found

	-v, --verbose
		print configuration prior to execution

	-q, --quiet
		only print files that exceed limit

	-h, --help
		print this help and exit"
	
	return 0
}

# print usage if no options
if [[ $# == 0 ]]
then
	print_help
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
	-g|--git)
		GIT=true
		;;
	-s|--submodules)
		SUBMODULES=true
		;;
	-v|--verbose)
		VERBOSE=true
		;;
	-q|--quiet)
		QUIET=true
		;;
	-h|--help)
		print_help
		exit 0
		;;
	*)
		# target only allowed as final option
		[[ $# != 1 ]] && printf '%s\n' 'invalid options' && exit 1
		TARGET="$1"
		;;
	esac

	shift
done

# verify options
[[ ! -e $TARGET ]] && printf '%s\n' 'invalid target' && exit 1

# exclude .git if enabled
if [[ ! $GIT ]]
then
	[[ $EXCLUDE ]] && EXCLUDE+='|'
	EXCLUDE+='(^.*/\.git/.*$)'
fi

# exclude git submodules if enabled
if [[ ! $SUBMODULES && -f ./.gitmodules ]]
then
	# add entry block
	[[ $EXCLUDE ]] && EXCLUDE+='|'
	EXCLUDE+='(^'

	# add module paths
	while read module
	do
		EXCLUDE+="(\\$module/.*)|"
	done \
		< <(grep -o 'path = .*' ./.gitmodules \
			| sed 's/path = /.\//')

	# remove trailing |, add exit block
	EXCLUDE="${EXCLUDE%?}$)"
fi

# print configuration if verbose
if [[ $VERBOSE ]]
then
	printf 'LIMIT: %s\n' "$LIMIT"
	printf 'TAB_SIZE: %s\n' "$TAB_SIZE"
	printf 'EXCLUDE: %s\n' "$EXCLUDE"
fi

# cd and unset failure var
cd "$TARGET"
unset FAIL

# loop over all files in path
while IFS= read -r -d '' file
do
	# check if file exceeds limit
	if [[ $(expand --tabs="$TAB_SIZE" "$file" \
		| awk "{ if (length(\$0) > $LIMIT) print \"y\" }") ]]
	then
		FAIL=true
		printf 'FAIL %s\n' "$file"
	else
		[[ ! $QUIET ]] && printf 'PASS %s\n' "$file"
	fi
done \
	< <(find . \
	-regextype posix-extended \
	-type f \
	-not -regex "$EXCLUDE" \
	-exec grep -Iq . '{}' \; \
	-and -print0)

[[ $FAIL ]] && exit 1
exit 0
