#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_LIB="${REPO_DIR}/lib/ui.sh"
BIN_DIR="${HOME}/.local/bin"
TARGET="${BIN_DIR}/dev.kit"
DEV_KIT_OWNER="${DEV_KIT_OWNER:-udx}"
DEV_KIT_REPO="${DEV_KIT_REPO:-dev.kit}"
ENGINE_DIR="${HOME}/.${DEV_KIT_OWNER}/${DEV_KIT_REPO}"
SOURCE_DIR="${ENGINE_DIR}/source"
STATE_DIR="${ENGINE_DIR}/state"
ENV_SRC="${REPO_DIR}/bin/env/dev-kit.sh"
ENV_DST="${SOURCE_DIR}/env.sh"
COMP_SRC_DIR="${REPO_DIR}/bin/completions"
COMP_DST_DIR="${SOURCE_DIR}/completions"
CONFIG_SRC="${REPO_DIR}/config/default.env"
CONFIG_DST="${STATE_DIR}/config.env"
LIB_SRC_DIR="${REPO_DIR}/lib"
LIB_DST_DIR="${SOURCE_DIR}/lib"
PROFILE=""

detect_profiles() {
  local found=""
  if [ -f "$HOME/.zshrc" ]; then found="$found $HOME/.zshrc"; fi
  if [ -f "$HOME/.bash_profile" ]; then found="$found $HOME/.bash_profile"; fi
  if [ -f "$HOME/.bashrc" ]; then found="$found $HOME/.bashrc"; fi
  if [ -f "$HOME/.profile" ]; then found="$found $HOME/.profile"; fi
  PROFILE=$(echo "$found" | tr ' ' '\n' | sort -u | tr '\n' ' ')
}

mkdir -p "$BIN_DIR"
mkdir -p "$ENGINE_DIR"

copy_dir_contents() {
  local src="$1"
  local dst="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  cp -R "$src/." "$dst/"
}

sync_engine() {
  # Use a temporary staging area for the source copy
  local stage
  stage="$(mktemp -d)"
  
  # Copy everything from REPO_DIR, excluding patterns that cause recursion
  # We use rsync if available for easier exclusion, otherwise fallback
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude 'tests/.tmp' --exclude '.git' "$REPO_DIR/" "$stage/"
  else
    # Fallback: copy specific top-level directories
    for d in bin lib templates docs src config scripts assets schemas tests; do
      [ -d "$REPO_DIR/$d" ] && copy_dir_contents "$REPO_DIR/$d" "$stage/$d"
    done
    [ -f "$REPO_DIR/environment.yaml" ] && cp "$REPO_DIR/environment.yaml" "$stage/environment.yaml"
  fi

  # Now sync from stage to SOURCE_DIR
  copy_dir_contents "$stage" "$SOURCE_DIR"
  rm -rf "$stage"
}

desired_target="${SOURCE_DIR}/bin/dev-kit"
if [ -f "$UI_LIB" ]; then
  # shellcheck disable=SC1090
  . "$UI_LIB"
fi

mkdir -p "$SOURCE_DIR"
mkdir -p "$STATE_DIR"

if command -v ui_header >/dev/null 2>&1; then
  ui_header "dev.kit | install"
else
  echo "----------------"
  echo " dev.kit | install "
  echo "----------------"
fi

sync_engine

if [ -L "$TARGET" ]; then
  current_target="$(readlink "$TARGET")"
  if [ "$current_target" != "$desired_target" ]; then
    ln -sf "$desired_target" "$TARGET"
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Symlink updated" "$TARGET -> $desired_target"
    else
      echo "OK  Symlink updated ($TARGET -> $desired_target)"
    fi
  else
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Already installed" "$TARGET"
    else
      echo "OK  Already installed ($TARGET)"
    fi
  fi
elif [ -e "$TARGET" ]; then
  if command -v ui_warn >/dev/null 2>&1; then
    ui_warn "Install skipped" "$TARGET exists and is not a symlink"
  else
    echo "WARN Install skipped ($TARGET exists and is not a symlink)"
  fi
else
  ln -s "$desired_target" "$TARGET"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Installed" "$TARGET"
  else
    echo "OK  Installed ($TARGET)"
  fi
fi

if [ -f "$ENV_SRC" ]; then
  cp "$ENV_SRC" "$ENV_DST"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Env installed" "$ENV_DST"
  else
    echo "OK  Env installed ($ENV_DST)"
  fi
fi

if [ ! -f "$ENGINE_DIR/env.sh" ]; then
  cat <<'EOF' > "$ENGINE_DIR/env.sh"
#!/bin/bash
DEV_KIT_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
. "$DEV_KIT_ENV_DIR/source/env.sh"
EOF
  chmod +x "$ENGINE_DIR/env.sh" 2>/dev/null || true
fi

if [ -d "$LIB_SRC_DIR" ]; then
  mkdir -p "$LIB_DST_DIR"
  cp "$LIB_SRC_DIR/ui.sh" "$LIB_DST_DIR/ui.sh" 2>/dev/null || true
fi

if [ -d "$COMP_SRC_DIR" ]; then
  mkdir -p "$COMP_DST_DIR"
  cp "$COMP_SRC_DIR/"* "$COMP_DST_DIR/" 2>/dev/null || true
fi

if [ -f "$CONFIG_SRC" ] && [ ! -f "$CONFIG_DST" ]; then
  cp "$CONFIG_SRC" "$CONFIG_DST"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Config installed" "$CONFIG_DST"
  else
    echo "OK  Config installed ($CONFIG_DST)"
  fi
fi

if [ -f "$CONFIG_DST" ] && [ ! -f "$ENGINE_DIR/config.env" ]; then
  cp "$CONFIG_DST" "$ENGINE_DIR/config.env"
fi

detect_profiles
env_line="source \"$SOURCE_DIR/env.sh\""
path_line="export PATH=\"$BIN_DIR:\$PATH\""

MODIFIED_PROFILES=""

if [ -t 0 ] && [ -n "$PROFILE" ]; then
  for p in $PROFILE; do
    echo ""
    if grep -Fqx "$env_line" "$p" && grep -Fqx "$path_line" "$p"; then
      if command -v ui_ok >/dev/null 2>&1; then
        ui_ok "Shell already configured" "$p"
      else
        echo "OK  Shell already configured ($p)"
      fi
      MODIFIED_PROFILES="$MODIFIED_PROFILES $p"
      continue
    fi

    printf "Configure dev.kit in %s? [y/N] " "$p"
    read -r answer || true
    case "$answer" in
      y|Y|yes|YES)
        if ! grep -Fqx "$path_line" "$p"; then
          printf "\n# dev.kit bin\n%s\n" "$path_line" >> "$p"
        fi
        if ! grep -Fqx "$env_line" "$p"; then
          printf "# dev.kit environment\n%s\n" "$env_line" >> "$p"
        fi
        if command -v ui_ok >/dev/null 2>&1; then
          ui_ok "Shell configured" "$p"
        else
          echo "OK  Shell configured ($p)"
        fi
        MODIFIED_PROFILES="$MODIFIED_PROFILES $p"
        ;;
      *)
        if command -v ui_warn >/dev/null 2>&1; then
          ui_warn "Skipped configuration" "$p"
        else
          echo "WARN Skipped configuration ($p)"
        fi
        ;;
    esac
  done
else
  if command -v ui_section >/dev/null 2>&1; then
    ui_section "Manual Configuration"
  else
    echo "Manual Configuration:"
  fi
  echo "Add the following to your shell profile:"
  echo "  $path_line"
  echo "  $env_line"
fi

echo ""
if command -v ui_section >/dev/null 2>&1; then
  ui_section "Ready to go"
else
  echo "Ready to go:"
fi

# Determine if the current shell's profile was modified
CURRENT_SHELL_PROFILE=""
case "$SHELL" in
  */zsh) CURRENT_SHELL_PROFILE="$HOME/.zshrc" ;;
  */bash) 
    [ -f "$HOME/.bash_profile" ] && CURRENT_SHELL_PROFILE="$HOME/.bash_profile" || CURRENT_SHELL_PROFILE="$HOME/.bashrc"
    ;;
esac

if [[ "$MODIFIED_PROFILES" == *"$CURRENT_SHELL_PROFILE"* ]]; then
  echo "1. Reload:         source $CURRENT_SHELL_PROFILE"
  echo "2. Brief:          dev.kit"
  echo ""
  if [ -t 0 ]; then
    printf "Reload current session now? [y/N] "
    read -r reload_now || true
    case "$reload_now" in
      y|Y|yes|YES)
        echo "Sourcing $CURRENT_SHELL_PROFILE..."
        # Note: We can source env.sh directly for immediate effect in this subshell
        # but the instructions tell the user how to fix their parent shell.
        source "$SOURCE_DIR/env.sh"
        dev.kit status
        ;;
    esac
  fi
else
  echo "1. Source Now:     source \"$SOURCE_DIR/env.sh\""
  echo "2. Brief:          dev.kit"
  echo ""
  echo "NOTE: Your current shell ($SHELL) was not permanently configured."
  if [ -t 0 ]; then
    printf "Source environment now? [y/N] "
    read -r source_now || true
    case "$source_now" in
      y|Y|yes|YES)
        echo "Sourcing..."
        source "$SOURCE_DIR/env.sh"
        dev.kit status
        ;;
    esac
  fi
fi
echo ""
