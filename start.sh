#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT=""
if compgen -G "$ROOT/tools/godot/Godot*" > /dev/null 2>&1; then
  GODOT=$(ls "$ROOT"/tools/godot/Godot* | head -n1)
fi
if [ -z "$GODOT" ]; then
  for c in godot godot4 Godot; do
    if command -v "$c" >/dev/null 2>&1; then GODOT=$(command -v "$c"); break; fi
  done
fi
if [ -z "$GODOT" ]; then
  echo "[错误] 未找到 Godot 4.x，请安装或将可执行文件放入 tools/godot/" >&2
  exit 1
fi
echo "使用引擎: $GODOT"
exec "$GODOT" --path "$ROOT"
