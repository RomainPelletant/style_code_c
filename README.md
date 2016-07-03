# CI Utilities - Style

Various scripts that check code style and can easily be automated.

Configuration flexibility is of very high importance to allow the scripts to be
easily used in a wide variety of configurations.

## line_limit.sh

Script that checks the line length of all text files in the specified target
path. Used for enforcing line length limits automatically.

```
./line_limit.sh [OPTION]... [TARGET]

        -l, --limit <limit>
                line limit in characters
                defaults to 80

        -t, --tab-size <size>
                tab size in characters
                defaults to 8

        -e, --exclude <expr>
                posix extended regex expression

        -g, --git
                do not exclude folders named .git

        -s, --submodules
                do not exclude git submodules

                by default git submodules are excluded
                by parsing $PWD/.gitmodules if it exists
                if it does not exist nothing is excluded
                the same applies to \$PWD/.gitmodules itself

        -v, --verbose
                print configuration prior to execution

        -q, --quiet
                only print files that exceed limit

        -h, --help
                print this help and exit
```
