#!/bin/sh
CLANG=6.0

set -e

apt-get update

apt-get install --no-install-recommends -y \
	clang-format-$CLANG

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

ln -s /usr/bin/clang-format-$CLANG /usr/local/bin/clang-format
