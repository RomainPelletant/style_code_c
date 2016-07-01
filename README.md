# CI Utilities - Style

Various scripts that check code style and can easily be automated.

Configuration flexibility is of very high importance to allow the scripts to be
easily used in a wide variety of configurations.

## line_limit.sh

Script that checks the line length of all text files in the specified target
path. Used for enforcing line length limits automatically.

Besides the limit and tab size, a posix extended regex expression (ERE) can
be used to indicate which files or paths should be excluded.

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
                also check the .git folder
                defaults to ignoring all .git folders

        -s, --submodules
                also check git submodules
                defaults to parsing $PWD/.gitmodules
                and excluding all paths found

        -v, --verbose
                print configuration prior to execution

        -q, --quiet
                only print files that exceed limit

        -h, --help
                print this help and exit
```
