#!/usr/bin/env bash
set -euo pipefail

# Helper script: publish the Windows build and run it under Wine
# Usage: ./scripts/run-in-wine.sh [--self-contained]

SELF_CONTAINED=false
if [ "${1-}" = "--self-contained" ]; then
  SELF_CONTAINED=true
fi

PREFIX=${WINEPREFIX:-$PWD/.wine}

echo "Using WINEPREFIX=$PREFIX (override with WINEPREFIX env var)"

echo "Restoring..."
dotnet restore

echo "Publishing for win-x64 (self-contained=${SELF_CONTAINED})..."
if [ "$SELF_CONTAINED" = true ]; then
  dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o out
else
  dotnet publish -c Release -r win-x64 --self-contained false -o out
fi

echo "Published to ./out"

if ! command -v wine64 >/dev/null 2>&1; then
  echo "wine64 is not installed in your PATH. Enter the nix dev shell that provides wine64."
  exit 1
fi

export WINEPREFIX="$PREFIX"
export WINEARCH=win64

echo "Attempting to run with wine64:"
wine64 out/ExceptionHandling.exe || {
  echo "Running under wine failed. Common fixes:"
  echo " - Install a compatible .NET runtime inside wine (for framework-dependent publish)." 
  echo "   Example (using winetricks): winetricks -q dotnet48 (or install .NET 6/7/8 manually)"
  echo " - Or publish self-contained: ./scripts/run-in-wine.sh --self-contained"
  exit 1
}
