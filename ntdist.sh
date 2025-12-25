#!/usr/bin/env bash
set -euo pipefail

APP="$1"
DEST="${2:-dist}"

if [[ ! -f "$APP" ]]; then
  echo "Usage: $0 app.exe [destdir]"
  exit 1
fi

mkdir -p "$DEST"

# Where MinGW DLLs live
MINGW_BIN="$(dirname "$(which gcc)")"

# System DLLs we must NOT redistribute
SYSTEM_DLL_RE='^(KERNEL32|USER32|GDI32|ADVAPI32|SHELL32|OLE32|OLEAUT32|COMDLG32|WS2_32|RPCRT4|SHLWAPI|IMM32|WINMM|SETUPAPI|VERSION|bcrypt|ntdll)\.dll$'

echo "Harvesting DLLs for $APP"

# Use ntldd if available, fallback to objdump
if command -v ntldd >/dev/null; then
  DEPS=$(ntldd -R "$APP" | awk '{print $1}' | grep '\.dll$' || true)
else
  DEPS=$(objdump -p "$APP" | awk '/DLL Name/ {print $3}')
fi

for dll in $DEPS; do
  # Skip system DLLs
  if [[ "$dll" =~ $SYSTEM_DLL_RE ]]; then
    continue
  fi

  # Locate DLL
  path=$(find "$MINGW_BIN" -iname "$dll" -print -quit || true)

  if [[ -z "$path" ]]; then
    echo "WARNING: $dll not found"
    continue
  fi

  echo "  copying $dll"
  cp -u "$path" "$DEST/"
done

echo "Done."
