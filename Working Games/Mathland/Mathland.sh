#!/bin/sh
echo -ne '\033c\033]0;Mathland\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Mathland.x86_64" "$@"
