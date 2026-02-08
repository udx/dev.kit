#!/bin/bash

dev_kit_codex_src_dir() {
  echo "$REPO_DIR/src/ai/integrations/codex"
}

dev_kit_codex_common_dir() {
  echo "$REPO_DIR/src/ai"
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
    return
  fi
  local home_val="${HOME:-}"
  local dev_home_val="${DEV_KIT_HOME:-}"
  local dev_source_val="${DEV_KIT_SOURCE:-}"
  local dev_state_val="${DEV_KIT_STATE:-}"
  mkdir -p "$(dirname "$dst")"
  awk -v home="$home_val" \
      -v dev_home="$dev_home_val" \
      -v dev_source="$dev_source_val" \
      -v dev_state="$dev_state_val" '
    {
      gsub("{{HOME}}", home)
      gsub("{{DEV_KIT_HOME}}", dev_home)
      gsub("{{DEV_KIT_SOURCE}}", dev_source)
      gsub("{{DEV_KIT_STATE}}", dev_state)
      print
    }
  ' "$src" > "$dst"
}

dev_kit_codex_clear_path() {
  local dst="$1"
  if [ -d "$dst" ]; then
    rm -rf "$dst"
  elif [ -e "$dst" ]; then
    rm -f "$dst"
  fi
}

dev_kit_codex_merge_path() {
  local src="$1"
  local dst="$2"
  if [ -d "$src" ]; then
    local file=""
    while IFS= read -r file; do
      [ -z "$file" ] && continue
      local rel="${file#$src/}"
      local out="$dst/$rel"
      mkdir -p "$(dirname "$out")"
      dev_kit_codex_replace_path "$file" "$out"
    done < <(find "$src" -type f)
    return
  fi
  dev_kit_codex_replace_path "$src" "$dst"
}

dev_kit_codex_plan_item() {
  local path="$1"
  local common=""
  local src=""
  local out=""
  common="$(dev_kit_codex_common_dir)"
  src="$(dev_kit_codex_src_dir)"
  out="$(mktemp -d)"
  local out_path="$out/$path"

  if [ -e "$out_path" ]; then
    dev_kit_codex_clear_path "$out_path"
  fi

  local common_item="$common/$path"
  local src_item="$src/$path"
  local applied="false"

  if [ -e "$common_item" ]; then
    dev_kit_codex_merge_path "$common_item" "$out_path"
    applied="true"
  fi
  if [ -e "$src_item" ]; then
    dev_kit_codex_merge_path "$src_item" "$out_path"
    applied="true"
  fi

  if [ "$applied" != "true" ]; then
    echo "Missing path in common or source: $path" >&2
    rm -rf "$out"
    return 1
  fi

  printf "%s\n" "$out_path"
}

dev_kit_codex_print_plan() {
  local path="$1"
  local out_path=""
  out_path="$(dev_kit_codex_plan_item "$path")"
  if [ -f "$out_path" ]; then
    cat "$out_path"
    rm -rf "$(dirname "$out_path")"
    return 0
  fi
  local file=""
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    printf "\n--- %s ---\n" "${file#$out_path/}"
    cat "$file"
  done < <(find "$out_path" -type f | sort)
  rm -rf "$(dirname "$out_path")"
}

dev_kit_cmd_codex() {
  shift || true
  local sub="${1:-}"
  local src=""
  local common=""
  local dst=""
  src="$(dev_kit_codex_src_dir)"
  common="$(dev_kit_codex_common_dir)"
  dst="$(dev_kit_codex_dst_dir)"

  case "$sub" in
    status|"")
      echo "source: $src"
      echo "common: $common"
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
        local common_item="$common/$item"
        local src_item="$src/$item"
        local dst_item="$dst/$item"
        if [ -e "$common_item" ]; then
          printf "common/%s: present\n" "$item"
        else
          printf "common/%s: missing\n" "$item"
        fi
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
        local common_item="$common/$item"
        local dst_item="$dst/$item"
        dev_kit_codex_clear_path "$dst_item"
        if [ -e "$common_item" ]; then
          dev_kit_codex_merge_path "$common_item" "$dst_item"
          echo "Applied: common/$item"
        fi
      done < <(dev_kit_codex_managed_items)
      while IFS= read -r item; do
        [ -z "$item" ] && continue
        local src_item="$src/$item"
        local dst_item="$dst/$item"
        if [ -e "$src_item" ]; then
          dev_kit_codex_merge_path "$src_item" "$dst_item"
          echo "Applied: source/$item"
        fi
      done < <(dev_kit_codex_managed_items)
      echo "Backup: $backup_dir"
      ;;
    config)
      local plan="false"
      local path="config.toml"
      shift || true
      while [ $# -gt 0 ]; do
        case "$1" in
          --plan)
            plan="true"
            ;;
          --path=*)
            path="${1#--path=}"
            ;;
          --path)
            shift
            path="${1:-}"
            ;;
          *)
            echo "Unknown codex config option: $1" >&2
            exit 1
            ;;
        esac
        shift || true
      done
      if [ "$plan" != "true" ]; then
        echo "codex config requires --plan" >&2
        exit 1
      fi
      dev_kit_codex_print_plan "$path"
      ;;
    compare)
      local path="config.toml"
      shift || true
      while [ $# -gt 0 ]; do
        case "$1" in
          --path=*)
            path="${1#--path=}"
            ;;
          --path)
            shift
            path="${1:-}"
            ;;
          *)
            echo "Unknown codex compare option: $1" >&2
            exit 1
            ;;
        esac
        shift || true
      done
      local out_path=""
      out_path="$(dev_kit_codex_plan_item "$path")"
      local dst_path="$dst/$path"
      if [ -d "$out_path" ] || [ -d "$dst_path" ]; then
        diff -ru "$out_path" "$dst_path" || true
      else
        diff -u "$out_path" "$dst_path" || true
      fi
      rm -rf "$(dirname "$out_path")"
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
  apply    Backup and apply src/ai/integrations/codex -> ~/.codex
  config   Render a planned file/dir from src/ai + src/ai/integrations/codex
  compare  Compare planned output vs ~/.codex
  restore  Restore the latest backup to ~/.codex

Examples:
  dev.kit codex config --plan --path=skills/dev-prompt
  dev.kit codex compare --path=skills/dev-prompt
CODEX_USAGE
      ;;
    *)
      echo "Unknown codex command: $sub" >&2
      echo "Run: dev.kit codex --help" >&2
      exit 1
      ;;
  esac
}
