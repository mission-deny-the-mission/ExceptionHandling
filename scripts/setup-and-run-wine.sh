#!/usr/bin/env bash
set -euo pipefail

# Helper: create a 64-bit Wine prefix, publish a Windows self-contained build
# (non-single-file) and run it under wine64. Useful inside the nix dev shell.
#
# Usage:
#   bash scripts/setup-and-run-wine.sh
#
# Optional env vars:
#   WINEPREFIX - custom wine prefix path (default: ./ .wine inside project)

# Default to a project-local wine prefix so running this project doesn't interfere
# with the user's global ~/.wine prefix. You can override with WINEPREFIX env var.
PREFIX=${WINEPREFIX:-$PWD/.wine}
BACKUP_DIR="${PREFIX}.bak.$(date +%s)"

echo "Checking prerequisites..."
if ! command -v dotnet >/dev/null 2>&1; then
  echo "ERROR: dotnet not found. Enter the dev shell (nix develop) or install dotnet."
  exit 1
fi

if ! command -v wine64 >/dev/null 2>&1; then
  echo "ERROR: wine64 not found in PATH. Enter the dev shell that provides wine64."
  exit 1
fi

echo "Using WINEPREFIX=$PREFIX"

if [ -d "$PREFIX" ]; then
  echo "Backing up existing prefix to $BACKUP_DIR"
  mv "$PREFIX" "$BACKUP_DIR"
fi

export WINEARCH=win64
export WINEPREFIX="$PREFIX"

echo "Initializing wine prefix (WINEARCH=win64)..."
wineboot --init || true

# Detect 32-bit prefix marker in system.reg and recreate if necessary
if [ -f "$PREFIX/system.reg" ] && grep -q '^#arch=win32' "$PREFIX/system.reg" 2>/dev/null; then
  echo "Detected a 32-bit prefix. Recreating as 64-bit..."
  rm -rf "$PREFIX"
  wineboot --init
fi

echo "Publishing self-contained Win-x64 (non-single-file) to ./out-nofs"
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=false -o out-nofs

echo "Trying to run: wine64 out-nofs/ExceptionHandling.exe"
if wine64 out-nofs/ExceptionHandling.exe; then
  echo "Application ran successfully under Wine."
  exit 0
else
  echo "Run failed — collecting wine debug output to wine-debug.log"
  WINEDEBUG=+loaddll,+file wine64 out-nofs/ExceptionHandling.exe &> wine-debug.log || true
  echo "Saved wine-debug.log. Inspect it or paste here for help."
  exit 2
fi
