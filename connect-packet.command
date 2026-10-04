#!/bin/zsh
cd "${0:A:h}" || exit 1
source ./scripts/common.zsh || exit 1
require_pat || exit 1
exec "$PAT_BIN" --config "$PWD/pat-packet.json" connect "${1:-${DEFAULT_GATEWAY:?Set DEFAULT_GATEWAY in local.env or pass an alias/URL}}"
