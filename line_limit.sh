#!/bin/bash

set -e
set -o pipefail

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
$0 [OPTION]... TARGET

	-e, --exclude <expr>
		posix extended regular expression

		do not specify the leading ./ for absolute paths
		if you need the ./ prefix, bug Melvin to implement
			--output-prefix like in regex_check.sh

		can be specified multiple times

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
		print out the exclude regex before find

	EXIT CODE
		0	all checked files compliant
		1	at least one non-compliant file
		2	internal error
		*	when any command fails because of 'set -e'"

	return 0
}

function exclude()
{
	[[ ! $1 ]] && printf 'invalid exclude()\n' && exit 1

	tmp="$1"
	# if already absolute, prefix the ./ which find needs
	[[ ${tmp:0:1} == '^' ]] && tmp="^\\./${tmp:1}"
	# make it full-path covering regex (find wants it)
	# prefix ^.* if not starting with ^
	[[ ${tmp:0:1} != '^' ]] && tmp="^.*$tmp"
	# append .*$ is not ending with $
	[[ ${tmp: -1} != '$' ]] && tmp="$tmp.*\$"

	[[ $EXCLUDE ]] && EXCLUDE+='|'
	EXCLUDE+="($tmp)"
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
		exclude "$2"
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

# exclude .git if enabled
if [[ ! $GIT ]]
then
	exclude '^\.git/.*$'
fi

# exclude git submodules if enabled
if [[ ! $SUBMODULES && -f ./.gitmodules ]]
then
	exclude '^\.gitmodules$'

	# add module paths
	while read module
	do
		exclude "^$module/.*$"
	done \
		< <(grep -o $'^[ \t]*path = .*' ./.gitmodules \
			| sed $'s/[ \t]*path = /.\//' \
			| sed $'s/\./\\\\./g')
fi

# print exclude regex if verbose
[[ $VERBOSE ]] && printf '%s\n' "$(echo "$EXCLUDE" | sed 's/\t/\\t/g')"

# loop over all files in path
while IFS= read -r -d '' file
do
	# strip leading ./
	file="${file:2}"

	set +e
	# check line limit for file
	expand --tabs="$TAB_SIZE" "$file" \
		| grep -EHInv --label="$file" "^.{0,$LIMIT}$"

	case $? in
	0)
		FAIL=true
		;;
	1)
		# no match, so all is ok
		;;
	*)
		exit 2
		;;
	esac
	set -e

	# continue if indent disabled
	[[ ! $INDENT ]] && continue

	# determine indent type for file
	# do not match c-style block comments to avoid misdetection as space
	# grep returns 1 when no match
	set +e
	indent_type="$(grep -EIo -m 1 $'^[ \t]+[^ \t\\*]' "$file")"
	set -e
	case "${indent_type:0:1}" in
	$' ')
		indent_match=$'(^$)|(^ *[^ \t])'
		;;
	$'\t')
		# do not match for c-style block comments /*\n *\n */
		# the non-opening lines will be "\t* \*"
		indent_match=$'(^$)|(^\t*([^\t ]| \\*))'
		;;
	*)
		# no indentations in file, skip
		continue
		;;
	esac

	# check for violating lines
	set +e
	grep -EHnv "$indent_match" "$file"

	case $? in
	0)
		FAIL=true
		;;
	1)
		# no match, so all is ok
		;;
	*)
		exit 2
		;;
	esac
	set -e
done \
	< <(find . \
	-regextype posix-extended \
	-type f \
	\! -regex "$EXCLUDE" \
	-print0)

[[ $FAIL ]] && exit 1
exit 0
