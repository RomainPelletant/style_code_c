#!/bin/bash

set -e

# defaults
unset EXCLUDE
unset GIT
unset INDENT
LIMIT=80
unset SUBMODULES
TAB_SIZE=8
unset VERBOSE
unset TARGET

# vars
unset FAIL

# functions
function print_help()
{
	printf '%s\n' "\
$0 [OPTION]... [TARGET]

	-e, --exclude <expr>
		posix extended regular expression
		do specify the leading ./ for absolute expressions

		on most shells use \$'regex' instead of 'regex' to avoid
		automatic expansion of characters like \\t

		will override a previous value

	-g, --git
		do not exclude folders named .git automatically

	-h, --help
		print this help and exit

	-i, --indent
		enable automatic indent type checking

		the first line of a file that starts with either
		a tab OR a space and contains non-whitespace afterwards will
		determine the indent checking to be used for the
		rest of the file

		if the first indent is mixed, as in contains both
		tabs and spaces, the very first character will be used

		an exception is made for '\\t *' for multi-line c-style comments
		during both indent detection and indent checking

	-l, --limit <limit>
		line limit in characters
		defaults to '$LIMIT'

	-s, --submodules
		do not exclude git submodules automatically
		applies to both the definition file and submodule paths

	-t, --tab-size <size>
		tab size in characters
		defaults to '$TAB_SIZE'

	-v, --verbose
		print out results for files that pass checks

	EXIT CODE
		0	all checked files compliant
		1	at least one non-compliant file
		*	when any command fails because of 'set -e'"

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
	-e|--exclude)
		EXCLUDE="$2"
		shift
		;;
	-g|--git)
		GIT=true
		;;
	-h|--help)
		print_help
		exit 0
		;;
	-i|--indent)
		INDENT=true
		;;
	-l|--limit)
		LIMIT="$2"
		shift
		;;
	-s|--submodules)
		SUBMODULES=true
		;;
	-t|--tab-size)
		TAB_SIZE="$2"
		shift
		;;
	-v|--verbose)
		VERBOSE=true
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
[[ ! -d $TARGET ]] && printf '%s\n' 'invalid target (not a dir)' && exit 1

# cd to target before parsing anything
cd "$TARGET"

# wrap the original exclude in parentheses
[[ $EXCLUDE ]] && EXCLUDE="($EXCLUDE)"

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

	# exclude ./.gitmodules
	EXCLUDE+='(\./\.gitmodules)|'

	# add module paths
	while read module
	do
		EXCLUDE+="(\\$module/.*)|"
	done \
		< <(grep -o $'^[ \t]*path = .*' ./.gitmodules \
			| sed 's/path = /.\//')

	# remove trailing |, add exit block
	EXCLUDE="${EXCLUDE%?}$)"
fi

# loop over all files in path
while IFS= read -r -d '' file
do
	# check if file exceeds limit
	if [[ $(expand --tabs="$TAB_SIZE" "$file" \
		| awk "{ if (length(\$0) > $LIMIT) print \"y\" }") ]]
	then
		FAIL=true
		printf 'LIMIT  FAIL %s\n' "$file"
	else
		[[ $VERBOSE ]] && printf 'LIMIT  PASS %s\n' "$file"
	fi

	# continue if indent disabled
	[[ ! $INDENT ]] && continue

	# determine indent type for file
	# do not match c-style block comments to avoid misdetection as space
	# grep returns 1 when no match
	set +e
	indent_type="$(grep -Eo -m 1 $'^[ \t]+[^ \t\\*]' "$file")"
	set -e
	indent_type="${indent_type:0:1}"
	case "$indent_type" in
	$' ')
		indent_match=$'(^$)|(^ *[^ \t])'
		;;
	$'\t')
		# do not match for c-style block comments /*\n *\n */
		# the non-opening lines will be "\t* \*"
		indent_match=$'(^$)|(^\t*([^\t ]| \\*))'
		;;
	*)
		[[ $VERBOSE ]] && printf 'INDENT SKIP %s\n' "$file"
		continue
		;;
	esac

	# check for violating lines
	if [[ $(grep -Ev -m 1 "$indent_match" "$file") ]]
	then
		FAIL=true
		printf 'INDENT FAIL %s\n' "$file"
	else
		[[ $VERBOSE ]] && printf 'INDENT PASS %s\n' "$file"
	fi
done \
	< <(find . \
	-regextype posix-extended \
	-type f \
	\! -regex "$EXCLUDE" \
	-exec grep -Iq . '{}' \; \
	-and -print0)

[[ $FAIL ]] && exit 1
exit 0
