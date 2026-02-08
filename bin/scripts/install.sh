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

detect_profile() {
  case "${SHELL:-}" in
    */zsh) PROFILE="$HOME/.zshrc" ;;
    */bash) PROFILE="$HOME/.bash_profile" ;;
    *) PROFILE="$HOME/.bash_profile" ;;
  esac
  if [ ! -f "$PROFILE" ]; then
    if [ -f "$HOME/.profile" ]; then
      PROFILE="$HOME/.profile"
    fi
  fi
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
  copy_dir_contents "$REPO_DIR/bin" "$SOURCE_DIR/bin"
  copy_dir_contents "$REPO_DIR/lib" "$SOURCE_DIR/lib"
  copy_dir_contents "$REPO_DIR/templates" "$SOURCE_DIR/templates"
  copy_dir_contents "$REPO_DIR/docs" "$SOURCE_DIR/docs"
  copy_dir_contents "$REPO_DIR/src" "$SOURCE_DIR/src"
  copy_dir_contents "$REPO_DIR/config" "$SOURCE_DIR/config"
  copy_dir_contents "$REPO_DIR/scripts" "$SOURCE_DIR/scripts"
  copy_dir_contents "$REPO_DIR/assets" "$SOURCE_DIR/assets"
  copy_dir_contents "$REPO_DIR/schemas" "$SOURCE_DIR/schemas"

  # Remove legacy command entrypoints that should no longer exist.
  rm -f "$SOURCE_DIR/lib/commands/promt.sh"
}

migrate_legacy_install() {
  if [ -d "$ENGINE_DIR" ] && [ ! -d "$SOURCE_DIR" ] && [ -d "$ENGINE_DIR/bin" ]; then
    mkdir -p "$SOURCE_DIR" "$STATE_DIR"
    local item=""
    for item in bin lib templates docs src config scripts assets schemas completions; do
      if [ -d "$ENGINE_DIR/$item" ]; then
        mv "$ENGINE_DIR/$item" "$SOURCE_DIR/$item"
      fi
    done
    if [ -f "$ENGINE_DIR/env.sh" ]; then
      mv "$ENGINE_DIR/env.sh" "$SOURCE_DIR/env.sh"
    fi
    if [ -f "$ENGINE_DIR/config.env" ]; then
      mv "$ENGINE_DIR/config.env" "$STATE_DIR/config.env"
    fi
    for item in capture exec logs; do
      if [ -d "$ENGINE_DIR/$item" ]; then
        mv "$ENGINE_DIR/$item" "$STATE_DIR/$item"
      fi
    done
    find "$ENGINE_DIR" -mindepth 1 -maxdepth 1 ! -name "source" ! -name "state" -exec rm -rf {} +
  fi
}

cleanup_legacy_paths() {
  local item=""
  for item in bin lib templates docs src config scripts assets schemas completions env.sh config.env capture exec logs; do
    if [ -e "$ENGINE_DIR/$item" ]; then
      rm -rf "$ENGINE_DIR/$item"
    fi
  done
}

desired_target="${SOURCE_DIR}/bin/dev-kit"
if [ -f "$UI_LIB" ]; then
  # shellcheck disable=SC1090
  . "$UI_LIB"
fi

migrate_legacy_install
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
cleanup_legacy_paths

if [ -L "$TARGET" ]; then
  current_target="$(readlink "$TARGET")"
  if [ "$current_target" != "$desired_target" ]; then
    ln -sf "$desired_target" "$TARGET"
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Symlink updated" "$TARGET -> $desired_target"
    else
      echo "OK  Symlink updated"
      echo "   $TARGET -> $desired_target"
    fi
  else
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Already installed" "$TARGET"
    else
      echo "OK  Already installed"
      echo "   $TARGET"
    fi
  fi
elif [ -e "$TARGET" ]; then
  if command -v ui_warn >/dev/null 2>&1; then
    ui_warn "Install skipped" "$TARGET exists and is not a symlink"
  else
    echo "WARN Install skipped"
    echo "   $TARGET exists and is not a symlink"
  fi
else
  ln -s "$desired_target" "$TARGET"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Installed" "$TARGET"
  else
    echo "OK  Installed"
    echo "   $TARGET"
  fi
fi

if [ -f "$ENV_SRC" ]; then
  cp "$ENV_SRC" "$ENV_DST"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Env installed" "$ENV_DST"
  else
    echo "OK  Env installed"
    echo "   $ENV_DST"
  fi
fi

if [ -d "$LIB_SRC_DIR" ]; then
  mkdir -p "$LIB_DST_DIR"
  cp "$LIB_SRC_DIR/ui.sh" "$LIB_DST_DIR/ui.sh" 2>/dev/null || true
  if [ -f "$LIB_DST_DIR/ui.sh" ]; then
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "UI installed" "$LIB_DST_DIR/ui.sh"
    else
      echo "OK  UI installed"
      echo "   $LIB_DST_DIR/ui.sh"
    fi
  fi
fi

if [ -d "$COMP_SRC_DIR" ]; then
  mkdir -p "$COMP_DST_DIR"
  cp "$COMP_SRC_DIR/"* "$COMP_DST_DIR/" 2>/dev/null || true
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Completions installed" "$COMP_DST_DIR"
  else
    echo "OK  Completions installed"
    echo "   $COMP_DST_DIR"
  fi
fi

if [ -f "$CONFIG_SRC" ] && [ ! -f "$CONFIG_DST" ]; then
  cp "$CONFIG_SRC" "$CONFIG_DST"
  if command -v ui_ok >/dev/null 2>&1; then
    ui_ok "Config installed" "$CONFIG_DST"
  else
    echo "OK  Config installed"
    echo "   $CONFIG_DST"
  fi
fi

if [ ! -w "$ENGINE_DIR" ] || [ ! -w "$SOURCE_DIR" ] || [ ! -w "$STATE_DIR" ]; then
  if command -v ui_warn >/dev/null 2>&1; then
    ui_warn "Config unavailable" "$ENGINE_DIR is not writable"
  else
    echo "WARN Config unavailable"
    echo "   $ENGINE_DIR is not writable"
  fi
  exit 1
fi

detect_profile
reload_cmd="source \"$PROFILE\""
case "$PROFILE" in
  "$HOME/.profile") reload_cmd="source \"$HOME/.profile\"" ;;
  "$HOME/.zshrc") reload_cmd="source \"$HOME/.zshrc\"" ;;
  "$HOME/.bash_profile") reload_cmd="source \"$HOME/.bash_profile\"" ;;
esac
path_line="export PATH=\"$BIN_DIR:\$PATH\""
path_prompt="true"
if [ -f "$CONFIG_DST" ]; then
  path_prompt="$(awk -F= '
    $1 ~ "^[[:space:]]*install.path_prompt[[:space:]]*$" {
      gsub(/[[:space:]]/,"",$2);
      print tolower($2);
      exit
    }
  ' "$CONFIG_DST")"
fi
if ! command -v dev.kit >/dev/null 2>&1; then
  if [ -n "$PROFILE" ] && [ -t 0 ] && [ "$path_prompt" != "false" ]; then
    if [ -f "$PROFILE" ] && grep -Fqx "$path_line" "$PROFILE"; then
      if command -v ui_ok >/dev/null 2>&1; then
        ui_ok "PATH already set" "$PROFILE"
      else
        echo "OK  PATH already set"
        echo "   $PROFILE"
      fi
    else
      printf "Add dev.kit to PATH in %s? [y/N] " "$PROFILE"
      read -r answer || true
      case "$answer" in
        y|Y|yes|YES)
          printf "\n%s\n" "$path_line" >> "$PROFILE"
          if command -v ui_ok >/dev/null 2>&1; then
            ui_ok "PATH updated" "$PROFILE"
            echo "   Reload your shell to use dev.kit"
          else
            echo "OK  PATH updated"
            echo "   $PROFILE"
            echo "   Reload your shell to use dev.kit"
          fi
          ;;
        *) ;;
      esac
    fi
    if command -v ui_section >/dev/null 2>&1; then
      ui_section "Next steps"
    else
      echo ""
      echo "Next steps"
    fi
    echo "  $reload_cmd"
    echo "  hash -r"
    exit 0
  else
    if command -v ui_section >/dev/null 2>&1; then
      ui_section "Next step (PATH)"
    else
      echo ""
      echo "Next step (PATH)"
    fi
    echo "  $path_line"
  fi
fi

echo ""
if command -v ui_section >/dev/null 2>&1; then
  ui_section "Next step (auto-init)"
else
  echo "Next step (auto-init)"
fi
env_line="source \"$SOURCE_DIR/env.sh\""
if [ -n "$PROFILE" ] && [ -t 0 ]; then
  if [ -f "$PROFILE" ] && grep -Fqx "$env_line" "$PROFILE"; then
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Auto-init already set" "$PROFILE"
    else
      echo "OK  Auto-init already set"
      echo "   $PROFILE"
    fi
  else
    printf "Add dev.kit auto-init to %s? [y/N] " "$PROFILE"
    read -r answer || true
    case "$answer" in
      y|Y|yes|YES)
        printf "\n%s\n" "$env_line" >> "$PROFILE"
        if command -v ui_ok >/dev/null 2>&1; then
          ui_ok "Auto-init added" "$PROFILE"
        else
          echo "OK  Auto-init added"
          echo "   $PROFILE"
        fi
        ;;
      *) ;;
    esac
  fi
else
  echo "  $env_line"
fi

echo ""
echo "  Reload your shell:"
echo "    $reload_cmd"
echo "    hash -r"
echo ""
echo "  Then run:"
echo "    dev.kit exec \"...\""
echo ""
