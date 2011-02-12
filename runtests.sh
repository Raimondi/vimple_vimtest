#!/bin/sh

for f in "$@"; do
  echo `expect runVimTests.expect "$f"`
done
