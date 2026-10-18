#!/bin/sh
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CC=${CC:-cc}
mkdir -p "$PROJECT_ROOT/rootfs/bin"
"$CC" -std=c11 -O2 -Wall -Wextra -Werror -static \
  -o "$PROJECT_ROOT/rootfs/bin/hutos" "$PROJECT_ROOT/src/hutos.c" -lm
chmod 0755 "$PROJECT_ROOT/rootfs/bin/hutos"
echo "[hutos] Built static CLI: rootfs/bin/hutos"
