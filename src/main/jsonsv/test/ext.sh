#!/usr/bin/env bash

echo "$1"

if [[ $1 == *.jsonsv ]]; then
  exit 0
else
  echo "JSONSV extension expected"
  exit 1
fi
