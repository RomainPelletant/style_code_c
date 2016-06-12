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

        -l, --limit
                line limit in characters
                defaults to 80

        -t, --tab-size
                tab size in characters
                defaults to 8

        -e, --exclude
                posix extended regex expression
```
