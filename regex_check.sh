#!/bin/bash

set -e
set -o pipefail

# defaults
unset EXCLUDE_DIR
declare -a EXCLUDE
unset EXCLUDE_FILE
unset GIT
unset SUBMODULES
LOCALE='C'
unset OUTPUT_PREFIX
unset OUTPUT_PREFIX_EXPR
REGEX=$'^[[:print:]\t]*$'
unset VERBOSE
unset TARGET

# functions
function print_help()
{
	printf '%s\n' "\
$0 [OPTION]... TARGET

	-d, --exclude-dir <glob>
		directory name glob exclude from check
		can be specified multiple times
		for details read grep(1) --exclude-dir

	-e, --exclude <expr>
		posix extended regular expression
		--exclude-dir and --exclude-file have better performance

		do not specify the leading ./ for absolute paths
		if you need the ./ prefix, use --output-prefix and do prefix
			--exclude's expr with whatever is specified there

		can be specified multiple times

	-f, --exclude-file <glob>
		filename glob to exclude from check
		can be specified multiple times
		for details read grep(1) --exclude

	-g, --git
		do not exclude folders named .git automatically

	-h, --help
		print this help and exit

	-l, --locale
		locale during grep execution
		defaults to '$LOCALE'

	-o, --output-prefix <string> <expr>
		prefix all output with STRING
		provide POSIX ERE EXPR to match STRING

		mainly intended for prefixing ./ for --exclude used as
		--output-prefix './' '\\./'

		will override a previous value

	-r, --regex
		posix extended regular expression for contents marked as valid
		defaults to ASCII-only \$'$(echo "$REGEX" | sed 's/\t/\\t/g')'

	-s, --submodules
		do not exclude git submodules automatically

	-v, --verbose
		print out the command string just before eval

	EXIT CODE
		0	all checked files compliant
		1	at least one non-compliant file
		2	internal error on eval
		*	when any command before eval fails because of 'set -e'"

	return 0
}

function exclude_dir()
{
	[[ ! $1 ]] && printf 'invalid exclude_dir()\n' && exit 1

	[[ $EXCLUDE_DIR ]] && EXCLUDE_DIR+=' '
	EXCLUDE_DIR+="--exclude-dir=\$'$1'"
}

function exclude()
{
	[[ ! $1 ]] && printf 'invalid exclude()\n' && exit 1

	EXCLUDE+=("$1")
}

function exclude_file()
{
	[[ ! $1 ]] && printf 'invalid exclude_file()\n' && exit 1

	[[ $EXCLUDE_FILE ]] && EXCLUDE_FILE+=' '
	EXCLUDE_FILE+="--exclude=\$'$1'"
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
	-d|--exclude-dir)
		exclude_dir "$2"
		shift
		;;
	-e|--exclude)
		exclude "$2"
		shift
		;;
	-f|--exclude-file)
		exclude_file "$2"
		shift
		;;
	-g|--git)
		GIT=true
		;;
	-h|--help)
		print_help
		exit 0
		;;
	-l|--locale)
		LOCALE="$2"
		shift
		;;
	-o|--output-prefix)
		OUTPUT_PREFIX="$2"
		OUTPUT_PREFIX_EXPR="$3"
		shift
		shift
		;;
	-r|--regex)
		REGEX="$2"
		shift
		;;
	-s|--submodules)
		SUBMODULES=true
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

# exclude all dirs named .git if enabled
if [[ ! $GIT ]]
then
	exclude_dir '.git'
fi

# exclude git submodules if enabled
# regular exclude means the first grep will still search, so the performance is
# suboptimal especially with large submodules
if [[ ! $SUBMODULES && -f ./.gitmodules ]]
then
	# add module paths
	while read module
	do
		exclude "^${OUTPUT_PREFIX_EXPR}$module/"
	done \
		< <(grep -o $'^[ \t]*path = .*' ./.gitmodules \
			| sed 's/path = //')
fi

# initial grep
cmd="export LC_ALL='$LOCALE';"
cmd+=' grep -EHInrv'
[[ $EXCLUDE_DIR ]] && cmd+=" $EXCLUDE_DIR"
[[ $EXCLUDE_FILE ]] && cmd+=" $EXCLUDE_FILE"
cmd+=" \$'$REGEX'"

# prefix prepending with sed
if [[ $OUTPUT_PREFIX ]]
then
	# escape / in the OUTPUT_PREFIX
	cmd+=" | sed \$'s/^/$(echo "$OUTPUT_PREFIX" | sed 's,/,\\/,g')/'"
fi

# exclude regex with a second grep
if (( ${#EXCLUDE[@]} > 0 ))
then
	cmd+=' | grep -Ev'

	# add exclude expressions
	for i in "${EXCLUDE[@]}"
	do
		cmd+=" -e $'$i'"
	done
fi

# eval built cmd
[[ $VERBOSE ]] && printf '%s\n' "$(echo "$cmd" | sed 's/\t/\\t/g')"
set +e
eval "$cmd"

case $? in
0)
	# line(s) selected, not compliant
	exit 1
	;;
1)
	# no lines selected, compliant
	exit 0
	;;
*)
	# unknown / internal error
	exit 2
	;;
esac
