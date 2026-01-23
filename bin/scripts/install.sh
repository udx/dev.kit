#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI_LIB="${REPO_DIR}/lib/ui.sh"
BIN_DIR="${HOME}/.local/bin"
TARGET="${BIN_DIR}/dev.kit"
KIT_CONFIG="${REPO_DIR}/config/kit.env"
kit_value() {
  local key="$1"
  local default="${2:-}"
  local val=""
  if [ -f "$KIT_CONFIG" ]; then
    val="$(awk -F= -v k="$key" '
      $1 ~ "^[[:space:]]*"k"[[:space:]]*$" {
        sub(/^[[:space:]]*/,"",$2);
        sub(/[[:space:]]*$/,"",$2);
        print $2;
        exit
      }
    ' "$KIT_CONFIG")"
  fi
  if [ -n "$val" ]; then
    echo "$val"
  else
    echo "$default"
  fi
}
DEV_KIT_OWNER="${DEV_KIT_OWNER:-$(kit_value OWNER "udx")}"
DEV_KIT_REPO="${DEV_KIT_REPO:-$(kit_value REPO "dev.kit")}"
ENGINE_DIR="${HOME}/.${DEV_KIT_OWNER}/${DEV_KIT_REPO}"
ENV_SRC="${REPO_DIR}/bin/env/dev-kit.sh"
ENV_DST="${ENGINE_DIR}/env.sh"
COMP_SRC_DIR="${REPO_DIR}/bin/completions"
COMP_DST_DIR="${ENGINE_DIR}/completions"
CONFIG_SRC="${REPO_DIR}/config/default.env"
CONFIG_DST="${ENGINE_DIR}/config.env"
LIB_SRC_DIR="${REPO_DIR}/lib"
LIB_DST_DIR="${ENGINE_DIR}/lib"
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

desired_target="${REPO_DIR}/bin/dev-kit"
if [ -f "$UI_LIB" ]; then
  # shellcheck disable=SC1090
  . "$UI_LIB"
fi

if command -v ui_header >/dev/null 2>&1; then
  ui_header "dev.kit | install"
else
  echo "----------------"
  echo " dev.kit | install "
  echo "----------------"
fi

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
  cp "$LIB_SRC_DIR/context.sh" "$LIB_DST_DIR/context.sh" 2>/dev/null || true
  if [ -f "$LIB_DST_DIR/context.sh" ]; then
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Lib installed" "$LIB_DST_DIR/context.sh"
    else
      echo "OK  Lib installed"
      echo "   $LIB_DST_DIR/context.sh"
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

if [ ! -w "$ENGINE_DIR" ]; then
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
shell_flag="--shell=bash"
case "${SHELL:-}" in
  */zsh) shell_flag="--shell=zsh" ;;
esac
path_line="export PATH=\"$BIN_DIR:\$PATH\""
if ! command -v dev.kit >/dev/null 2>&1; then
  if [ -n "$PROFILE" ] && [ -t 0 ]; then
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
      ui_section "Next steps (activate)"
    else
      echo ""
      echo "Next steps (activate)"
    fi
    echo "  $reload_cmd"
    echo "  hash -r"
    echo "  dev.kit enable $shell_flag"
    echo ""
    echo "  Or run once:"
    echo "  ${REPO_DIR}/bin/dev-kit enable $shell_flag"
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
echo "  dev.kit enable $shell_flag"
echo ""
