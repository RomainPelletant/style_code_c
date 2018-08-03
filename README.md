# CI CD / Style

Various scripts that check code style and can easily be used in CI.

* `clang_format.sh` Source code format checker and in-place modifier.
* `line_limit.sh` Line limit and per-file indentation style.
* `regex_check.sh` File content regex compliancy.

## clang\_format.sh

Script that uses clang-format to check or format source code. When checking
replacements are reported in XML. When formatting sources are modified in-place.

Dependencies:
* bash
* clang-format
* grep
* sort

```
usage: ./clang_format.sh [OPTION]... check|format

	-c, --clang-format <PATH>
		path to clang-format,
		defaults to the result of 'command -v clang-format'

	-p, --pattern <PATTERN>
		pattern to use to get which files to check,
		defaults to '{src,include,test}/**/*.{c,h,cpp,hpp}' if nothing
		is specified,
		can be specified multiple times

	-v, --verbose
		print list of files as that are checked

	check
		check sources and report replacements

	format
		format sources in place

	EXIT CODE
		0	[check] no replacements
			[format] completed ok
		1	[check] found replacements
		2	internal error
		3	invalid arguments
		*	when any commands fails because of 'set -e'"
```

## line\_limit.sh

Script that checks the line length of all text files in the specified target
path. Used for enforcing line length limits automatically. It also supports
checking for consistent indention style on a per-file basis.

Dependencies:
* bash
* expand
* grep
* sed

```
./line_limit.sh [OPTION]... TARGET

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

		an exception is made for '\t *' for multi-line c-style comments
		during both indent detection and indent checking

	-l, --limit <limit>
		line limit in characters
		defaults to '80'

	-s, --submodules
		do not exclude git submodules automatically
		applies to both the definition file and submodule paths

	-t, --tab-size <size>
		tab size in characters
		defaults to '8'

	-v, --verbose
		print out the exclude regex before find

	EXIT CODE
		0	all checked files compliant
		1	at least one non-compliant file
		2	internal error
		*	when any command fails because of 'set -e'
```

## regex\_check.sh

Script that checks files for specified POSIX extended regular expression,
defaulting to checking whether file is basic ASCII compliant.

Primary use case is to avoid non-ASCII characters in source code. Script is
flexible enough to be used in many other ways that deal with regex compliancy.

Dependencies:
* bash
* grep
* sed

```
./regex_check.sh [OPTION]... TARGET

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
		defaults to 'C'

	-o, --output-prefix <string> <expr>
		prefix all output with STRING
		provide POSIX ERE EXPR to match STRING

		mainly intended for prefixing ./ for --exclude used as
		--output-prefix './' '\./'

		will override a previous value

	-r, --regex
		posix extended regular expression for contents marked as valid
		defaults to ASCII-only $'^[[:print:]\t]*$'

	-s, --submodules
		do not exclude git submodules automatically

	-v, --verbose
		print out the command string just before eval

	EXIT CODE
		0	all checked files compliant
		1	at least one non-compliant file
		2	internal error on eval
		*	when any command before eval fails because of 'set -e'
```
