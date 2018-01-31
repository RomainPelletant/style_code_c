# CI CD / Style

Various scripts that check code style and can easily be used in CI.

* `regex_check.sh` File content regex compliancy.
* `line_limit.sh` Line limit and per-file indentation style.

## regex\_check.sh

Script that checks files for specified POSIX extended regular expression,
defaulting to checking whether file is basic ASCII compliant.

Primary use case is to avoid non-ASCII characters in source code. Script is
flexible enough to be used in many other ways that deal with regex compliancy.

```
./regex_check.sh [OPTION]... [TARGET]

        -d, --exclude-dir <glob>
                directory name glob exclude from check
                can be specified multiple times
                for details read grep(1) --exclude-dir

        -e, --exclude <expr>
                posix extended regular expression
                --exclude-dir and --exclude-file have better performance

                do not specify the leading ./
                if you need the ./ prefix, use --output-prefix

                on most shells use $'regex' instead of 'regex' to avoid
                automatic expansion of characters like \t

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

                on most shells use $'regex' instead of 'regex' for c-style
                automatic expansion of characters like \t

        -s, --submodules
                do not exclude git submodules automatically

        -v, --verbose
                print out the command string just before eval

        EXIT CODE
                0       all checked files compliant
                1       at least one non-compliant file
                2       internal error on eval
                *       when any command before eval fails because of 'set -e'
```

## line\_limit.sh

Script that checks the line length of all text files in the specified target
path. Used for enforcing line length limits automatically.

```
./line_limit.sh [OPTION]... [TARGET]

        -e, --exclude <expr>
                posix extended regex expression

        -g, --git
                do not exclude folders named .git automatically
                note that it adds to the exclude regex with OR internally
                -e, --exclude is therefore always in effect

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
                defaults to 80

        -s, --submodules
                do not exclude git submodules automatically
                note that it adds to the exclude regex with OR internally
                -e, --exclude is therefore always in effect

                by default git submodules are excluded
                by parsing $PWD/.gitmodules if it exists
                if it does not exist nothing is excluded
                the same applies to $PWD/.gitmodules itself

        -t, --tab-size <size>
                tab size in characters
                defaults to 8

        -v, --verbose
                also print out results for files that pass tests
```
