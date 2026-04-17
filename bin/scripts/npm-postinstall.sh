#!/usr/bin/env bash
# npm postinstall: detect and remove curl-based dev.kit installation.
# Runs silently when no curl install is found. Never fails the npm install.

curl_home="${DEV_KIT_HOME:-$HOME/.udx/dev.kit}"
curl_bin="${DEV_KIT_BIN_DIR:-$HOME/.local/bin}/dev.kit"

# Nothing to do if neither artifact exists.
[ -d "$curl_home" ] || [ -e "$curl_bin" ] || [ -L "$curl_bin" ] || exit 0

# If the symlink exists, verify it points to the curl install home.
# If it points elsewhere (local clone, another tool), leave it alone.
if [ -L "$curl_bin" ]; then
  link_target="$(readlink "$curl_bin" 2>/dev/null || true)"
  case "$link_target" in
    "$curl_home"/*) ;;
    *) exit 0 ;;
  esac
fi

echo ""
echo "dev.kit: detected previous curl-based installation"
[ -d "$curl_home" ] && echo "  home:   $curl_home"
[ -e "$curl_bin" ] || [ -L "$curl_bin" ] && echo "  binary: $curl_bin"

# Remove the binary symlink / file.
if [ -L "$curl_bin" ] || [ -f "$curl_bin" ]; then
  rm -f "$curl_bin" 2>/dev/null || true
fi

# Remove the curl install home directory.
if [ -d "$curl_home" ]; then
  rm -rf "$curl_home" 2>/dev/null || true
fi

# Clean up empty parent dirs left behind.
curl_bin_dir="$(dirname "$curl_bin" 2>/dev/null || true)"
if [ -n "$curl_bin_dir" ] && [ -d "$curl_bin_dir" ] && [ -z "$(ls -A "$curl_bin_dir" 2>/dev/null)" ]; then
  rmdir "$curl_bin_dir" 2>/dev/null || true
fi

echo ""
echo "  removed — npm version is now the single install"
echo ""
