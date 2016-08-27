# CI Utilities - Style

Various scripts that check code style and can easily be automated.

Configuration flexibility is of very high importance to allow the scripts to be
easily used in a wide variety of configurations.

## line_limit.sh

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

        -i, --ignore-indent
                disable automatic indent type checking
                this feature is enabled by default

                the first line of a file that starts with either
                a tab OR a space and contains non-whitespace afterwards will
                determine the indent checking to be used for the
                rest of the file

                if the first indent is mixed, as in contains both
                tabs and spaces, the very first character will be used

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
