#!/usr/bin/env bash

# dev.kit NPM Module
# Manages health, discovery, and installation hints for @udx-scoped CLI tools.

# Check if an NPM package/binary is healthy
# Usage: dev_kit_npm_health "@udx/mcurl" "mcurl"
dev_kit_npm_health() {
  local pkg="$1"
  local bin="${2:-}"
  
  # If no binary name provided, extract it from the package name (strip @scope/)
  [ -z "$bin" ] && bin="$(echo "$pkg" | sed 's/.*[\/]//')"
  
  if command -v "$bin" >/dev/null 2>&1; then
    return 0 # Binary installed and in PATH
  fi
  
  if command -v npm >/dev/null 2>&1; then
    return 2 # npm available, package can be installed
  fi
  
  return 1 # npm missing
}

# Generate an installation hint for an NPM package
dev_kit_npm_install_hint() {
  local pkg="$1"
  local bin="${2:-}"
  [ -z "$bin" ] && bin="$(echo "$pkg" | sed 's/.*[\/]//')"
  
  dev_kit_npm_health "$pkg" "$bin"
  local status=$?
  
  if [ $status -eq 2 ]; then
    echo "Hint: Install the '$bin' tool for deterministic resolution:" >&2
    echo "      npm install -g $pkg" >&2
  fi
}
