#!/bin/zsh
cd "${0:A:h}" || exit 1
source ./scripts/common.zsh || exit 1
require_file ./tncd.ini || exit 1
require_executable ./tncd || exit 1
require_free_port 8000 || exit 1
exec ./tncd -c tncd.ini -v
