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
BACKUP_DIR="${ENGINE_DIR}/backups"
ENV_SRC="${REPO_DIR}/bin/env/dev-kit.sh"
ENV_DST="${SOURCE_DIR}/env.sh"
COMP_SRC_DIR="${REPO_DIR}/bin/completions"
COMP_DST_DIR="${SOURCE_DIR}/completions"
CONFIG_SRC="${REPO_DIR}/config/default.env"
CONFIG_DST="${STATE_DIR}/config.env"
LIB_SRC_DIR="${REPO_DIR}/lib"
LIB_DST_DIR="${SOURCE_DIR}/lib"
PROFILE=""

if [ -f "$UI_LIB" ]; then
  # shellcheck disable=SC1090
  . "$UI_LIB"
fi

confirm_action() {
  local msg="$1"
  if [ -t 0 ]; then
    printf "%s [y/N] " "$msg"
    read -r answer || true
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      *) return 1 ;;
    esac
  fi
  return 0
}

backup_existing() {
  if [ -d "$ENGINE_DIR" ]; then
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$BACKUP_DIR"
    local backup_path="${BACKUP_DIR}/backup_${ts}.tar.gz"
    if command -v ui_info >/dev/null 2>&1; then
      ui_info "Backing up existing installation..." "$backup_path"
    else
      echo "INFO Backing up existing installation to $backup_path"
    fi
    tar -czf "$backup_path" -C "$(dirname "$ENGINE_DIR")" "$(basename "$ENGINE_DIR")" --exclude="backups" 2>/dev/null || true
  fi
}

detect_profiles() {
  local found=""
  if [ -f "$HOME/.zshrc" ]; then found="$found $HOME/.zshrc"; fi
  if [ -f "$HOME/.bash_profile" ]; then found="$found $HOME/.bash_profile"; fi
  if [ -f "$HOME/.bashrc" ]; then found="$found $HOME/.bashrc"; fi
  if [ -f "$HOME/.profile" ]; then found="$found $HOME/.profile"; fi
  PROFILE=$(echo "$found" | tr ' ' '\n' | sort -u | tr '\n' ' ')
}

copy_dir_contents() {
  local src="$1"
  local dst="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  cp -R "$src/." "$dst/"
}

sync_engine() {
  local stage
  stage="$(mktemp -d)"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude 'tests/.tmp' --exclude '.git' "$REPO_DIR/" "$stage/"
  else
    for d in bin lib templates docs src config scripts assets schemas tests; do
      [ -d "$REPO_DIR/$d" ] && copy_dir_contents "$REPO_DIR/$d" "$stage/$d"
    done
    [ -f "$REPO_DIR/environment.yaml" ] && cp "$REPO_DIR/environment.yaml" "$stage/environment.yaml"
    [ -f "$REPO_DIR/README.md" ] && cp "$REPO_DIR/README.md" "$stage/README.md"
  fi
  copy_dir_contents "$stage" "$SOURCE_DIR"
  rm -rf "$stage"
}

if command -v ui_header >/dev/null 2>&1; then
  ui_header "dev.kit | install"
else
  echo "----------------"
  echo " dev.kit | install "
  echo "----------------"
fi

if ! confirm_action "Proceed with dev.kit installation/update?"; then
  echo "Installation cancelled."
  exit 0
fi

backup_existing

mkdir -p "$BIN_DIR"
mkdir -p "$ENGINE_DIR"
mkdir -p "$SOURCE_DIR"
mkdir -p "$STATE_DIR"

sync_engine

desired_target="${SOURCE_DIR}/bin/dev-kit"
if [ -L "$TARGET" ]; then
  current_target="$(readlink "$TARGET")"
  if [ "$current_target" != "$desired_target" ]; then
    ln -sf "$desired_target" "$TARGET"
    if command -v ui_ok >/dev/null 2>&1; then
      ui_ok "Symlink updated" "$TARGET -> $desired_target"
    else
      echo "OK  Symlink updated ($TARGET -> $desired_target)"
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
fi

detect_profiles
env_line="source \"$SOURCE_DIR/env.sh\""
path_line="export PATH=\"$BIN_DIR:\$PATH\""

MODIFIED_PROFILES=""

if [ -t 0 ] && [ -n "$PROFILE" ]; then
  for p in $PROFILE; do
    if grep -Fqx "$env_line" "$p" && grep -Fqx "$path_line" "$p"; then
      MODIFIED_PROFILES="$MODIFIED_PROFILES $p"
      continue
    fi

    if confirm_action "Configure dev.kit in $p?"; then
      if ! grep -Fqx "$path_line" "$p"; then
        printf "\n# dev.kit bin\n%s\n" "$path_line" >> "$p"
      fi
      if ! grep -Fqx "$env_line" "$p"; then
        printf "# dev.kit environment\n%s\n" "$env_line" >> "$p"
      fi
      MODIFIED_PROFILES="$MODIFIED_PROFILES $p"
    fi
  done
fi

echo ""
if command -v ui_section >/dev/null 2>&1; then
  ui_section "Ready to go"
else
  echo "Ready to go:"
fi

CURRENT_SHELL_PROFILE=""
# Robust shell detection
case "$(basename "${SHELL:-}")" in
  zsh) 
    CURRENT_SHELL_PROFILE="$HOME/.zshrc"
    ;;
  bash) 
    if [[ "$OSTYPE" == "darwin"* ]]; then
      CURRENT_SHELL_PROFILE="$HOME/.bash_profile"
    else
      CURRENT_SHELL_PROFILE="$HOME/.bashrc"
    fi
    ;;
  *)
    # Fallback: check which profile we actually modified
    for p in $MODIFIED_PROFILES; do
      CURRENT_SHELL_PROFILE="$p"
      break
    done
    ;;
esac

if [[ "$MODIFIED_PROFILES" == *"$CURRENT_SHELL_PROFILE"* ]]; then
  echo "1. Reload:         source $CURRENT_SHELL_PROFILE"
  echo "2. Run:            dev.kit"
  if [ -t 0 ]; then
    if confirm_action "Reload current session now?"; then
      source "$SOURCE_DIR/env.sh"
      dev.kit status
    fi
  fi
else
  echo "1. Source Now:     source \"$SOURCE_DIR/env.sh\""
  echo "2. Run:            dev.kit"
fi
echo ""

