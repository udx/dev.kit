#!/bin/bash

dev_kit_codex_src_dir() {
  echo "$REPO_DIR/templates/ai/codex"
}

dev_kit_codex_dst_dir() {
  echo "$HOME/.codex"
}

dev_kit_codex_managed_items() {
  printf "%s\n" "AGENTS.md" "config.toml" "rules" "skills"
}

dev_kit_codex_backup_dir() {
  local base=""
  base="$(dev_kit_codex_dst_dir)"
  echo "$base/.backup/dev.kit"
}

dev_kit_codex_latest_backup() {
  local base=""
  base="$(dev_kit_codex_backup_dir)"
  if [ -d "$base" ]; then
    ls -1t "$base" 2>/dev/null | head -n 1 || true
  fi
}

dev_kit_codex_replace_path() {
  local src="$1"
  local dst="$2"
  if [ -d "$dst" ]; then
    rm -rf "$dst"
  elif [ -e "$dst" ]; then
    rm -f "$dst"
  fi
  if [ -d "$src" ]; then
    cp -R "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
}

dev_kit_cmd_codex() {
  shift || true
  local sub="${1:-}"
  local src=""
  local dst=""
  src="$(dev_kit_codex_src_dir)"
  dst="$(dev_kit_codex_dst_dir)"

  case "$sub" in
    status|"")
      echo "source: $src"
      echo "target: $dst"
      if command -v codex >/dev/null 2>&1; then
        echo "codex: installed"
      else
        echo "codex: missing"
      fi
      local latest=""
      latest="$(dev_kit_codex_latest_backup)"
      if [ -n "$latest" ]; then
        echo "backup: $(dev_kit_codex_backup_dir)/$latest"
      else
        echo "backup: none"
      fi
      local item=""
      while IFS= read -r item; do
        [ -z "$item" ] && continue
        local src_item="$src/$item"
        local dst_item="$dst/$item"
        if [ -e "$src_item" ]; then
          printf "source/%s: present\n" "$item"
        else
          printf "source/%s: missing\n" "$item"
        fi
        if [ -e "$dst_item" ]; then
          printf "target/%s: present\n" "$item"
        else
          printf "target/%s: missing\n" "$item"
        fi
      done < <(dev_kit_codex_managed_items)
      ;;
    apply)
      if [ ! -d "$src" ]; then
        echo "Missing source directory: $src" >&2
        exit 1
      fi
      mkdir -p "$dst"
      local backup_base=""
      backup_base="$(dev_kit_codex_backup_dir)"
      local backup_dir="$backup_base/$(date +%Y%m%d%H%M%S)"
      mkdir -p "$backup_dir"
      local item=""
      while IFS= read -r item; do
        [ -z "$item" ] && continue
        local dst_item="$dst/$item"
        if [ -e "$dst_item" ]; then
          mkdir -p "$backup_dir/$(dirname "$item")"
          cp -R "$dst_item" "$backup_dir/$item"
        fi
      done < <(dev_kit_codex_managed_items)
      while IFS= read -r item; do
        [ -z "$item" ] && continue
        local src_item="$src/$item"
        local dst_item="$dst/$item"
        if [ -e "$src_item" ]; then
          dev_kit_codex_replace_path "$src_item" "$dst_item"
          echo "Applied: $item"
        fi
      done < <(dev_kit_codex_managed_items)
      echo "Backup: $backup_dir"
      ;;
    restore)
      local latest=""
      latest="$(dev_kit_codex_latest_backup)"
      if [ -z "$latest" ]; then
        echo "No backups found in $(dev_kit_codex_backup_dir)" >&2
        exit 1
      fi
      local backup_dir="$(dev_kit_codex_backup_dir)/$latest"
      local item=""
      while IFS= read -r item; do
        [ -z "$item" ] && continue
        local src_item="$backup_dir/$item"
        local dst_item="$dst/$item"
        if [ -e "$src_item" ]; then
          dev_kit_codex_replace_path "$src_item" "$dst_item"
          echo "Restored: $item"
        fi
      done < <(dev_kit_codex_managed_items)
      echo "Restored from: $backup_dir"
      ;;
    help|-h|--help)
      cat <<'CODEX_USAGE'
Usage: dev.kit codex <command>

Commands:
  status   Show Codex integration status (default)
  apply    Backup and apply templates/ai/codex -> ~/.codex
  restore  Restore the latest backup to ~/.codex
CODEX_USAGE
      ;;
    *)
      echo "Unknown codex command: $sub" >&2
      echo "Run: dev.kit codex --help" >&2
      exit 1
      ;;
  esac
}
