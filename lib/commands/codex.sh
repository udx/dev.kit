#!/bin/bash

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

dev_kit_codex_integration_dir() {
  echo "$REPO_DIR/src/ai/integrations/codex"
}

dev_kit_codex_data_dir() {
  echo "$REPO_DIR/src/ai/data"
}

dev_kit_codex_templates_dir() {
  echo "$REPO_DIR/src/ai/integrations/codex/templates"
}

dev_kit_codex_schemas_dir() {
  echo "$REPO_DIR/src/ai/integrations/codex/schemas"
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

dev_kit_codex_require_jq() {
  if ! dev_kit_require_cmd "jq" "dev.kit codex rendering"; then
    exit 1
  fi
}

dev_kit_codex_clear_path() {
  local dst="$1"
  if [ -d "$dst" ]; then
    rm -rf "$dst"
  elif [ -e "$dst" ]; then
    rm -f "$dst"
  fi
}

dev_kit_codex_apply_placeholders() {
  local input="$1"
  local output="$2"
  local tmp_out=""
  local home_val="${HOME:-}"
  local dev_home_val="${DEV_KIT_HOME:-}"
  local dev_source_val="${DEV_KIT_SOURCE:-}"
  local dev_state_val="${DEV_KIT_STATE:-}"
  tmp_out="$(mktemp)"
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
  ' "$input" > "$tmp_out"
  mv "$tmp_out" "$output"
}

dev_kit_codex_render_template() {
  local template="$1"
  local out="$2"
  shift 2
  cp "$template" "$out"
  local key=""
  local val=""
  local tmp_val=""
  local tmp_out=""
  local key_re=""
  while [ $# -gt 1 ]; do
    key="$1"
    val="$2"
    shift 2
    key_re="$(printf '%s' "{{${key}}}" | sed 's/[][\\.^$*+?{}|()]/\\\\&/g')"
    tmp_val="$(mktemp)"
    tmp_out="$(mktemp)"
    printf "%s" "$val" > "$tmp_val"
    awk -v key="$key_re" -v file="$tmp_val" '
      BEGIN {
        val = ""
        first = 1
        while ((getline line < file) > 0) {
          if (first == 1) {
            val = line
            first = 0
          } else {
            val = val "\n" line
          }
        }
        close(file)
      }
      {
        gsub(key, val)
        print
      }
    ' "$out" > "$tmp_out"
    mv "$tmp_out" "$out"
    rm -f "$tmp_val"
  done
}

dev_kit_codex_validate_required() {
  local schema="$1"
  local data="$2"
  local req=""
  req="$(jq -r '.required[]?' "$schema")"
  local field=""
  for field in $req; do
    if ! jq -e --arg f "$field" 'has($f) and .[$f] != null' "$data" >/dev/null; then
      echo "Missing required field '$field' in $data" >&2
      exit 1
    fi
  done
}

dev_kit_codex_render_agents() {
  local data_dir=""
  local templ_dir=""
  local schema_dir=""
  local out_dir="$1"
  data_dir="$(dev_kit_codex_data_dir)"
  templ_dir="$(dev_kit_codex_templates_dir)"
  schema_dir="$(dev_kit_codex_schemas_dir)"

  local data="$data_dir/agents.json"
  dev_kit_codex_validate_required "$schema_dir/agents.schema.json" "$data"
  local title intro sections
  title="$(jq -r '.title' "$data")"
  intro="$(jq -r '.intro[]' "$data" | awk 'NR==1{print;next}{print "";print}')"
  sections="$(jq -r '.sections[] | "## " + .title + "\n" + (.bullets|map("- " + .)|join("\n"))' "$data" | awk 'NR==1{print;next}{print "";print}')"

  dev_kit_codex_render_template "$templ_dir/agents.md.tmpl" "$out_dir/AGENTS.md" \
    TITLE "$title" \
    INTRO "$intro" \
    SECTIONS "$sections"
}

dev_kit_codex_render_config() {
  local data_dir=""
  local templ_dir=""
  local schema_dir=""
  local out_dir="$1"
  data_dir="$(dev_kit_codex_data_dir)"
  templ_dir="$(dev_kit_codex_templates_dir)"
  schema_dir="$(dev_kit_codex_schemas_dir)"

  local data="$data_dir/config.json"
  dev_kit_codex_validate_required "$schema_dir/config.schema.json" "$data"
  local body
  body="$(jq -r '
    def q: @json;
    "approval_policy = " + (.approval_policy|q),
    "sandbox_mode = " + (.sandbox_mode|q),
    "web_search = " + (.web_search|q),
    "web_search_request = " + (.web_search_request|tostring),
    "personality = " + (.personality|q),
    "",
    "project_root_markers = " + (.project_root_markers|@json),
    "",
    (.projects|to_entries[]? | "[projects.\"" + .key + "\"]\n" + "trust_level = " + (.value.trust_level|q) + "\n"),
    "",
    (.mcp_servers|to_entries[]? | "[mcp_servers." + .key + "]\n"
      + (if .value.command then "command = " + (.value.command|q) + "\n" else "" end)
      + (if .value.args then "args = " + (.value.args|@json) + "\n" else "" end)
      + (if .value.url then "url = " + (.value.url|q) + "\n" else "" end)
    ),
    "",
    "[notice]",
    "hide_rate_limit_model_nudge = " + (.notice.hide_rate_limit_model_nudge|tostring),
    "",
    "[sandbox_workspace_write]",
    "network_access = " + (.sandbox_workspace_write.network_access|tostring),
    "writable_roots = " + (.sandbox_workspace_write.writable_roots|@json),
    "",
    "[shell_environment_policy]",
    "inherit = " + (.shell_environment_policy.inherit|q),
    "set = { PATH = " + (.shell_environment_policy.set.PATH|q) + " }",
    "include_only = " + (.shell_environment_policy.include_only|@json)
  ' "$data")"

  dev_kit_codex_render_template "$templ_dir/config.toml.tmpl" "$out_dir/config.toml" \
    CONFIG_BODY "$body"
}

dev_kit_codex_render_rules() {
  local data_dir=""
  local templ_dir=""
  local schema_dir=""
  local out_dir="$1"
  data_dir="$(dev_kit_codex_data_dir)"
  templ_dir="$(dev_kit_codex_templates_dir)"
  schema_dir="$(dev_kit_codex_schemas_dir)"

  local data="$data_dir/rules.json"
  dev_kit_codex_validate_required "$schema_dir/rules.schema.json" "$data"
  local body
  body="$(jq -r '
    (.header[]),
    "",
    (.groups[] | "# " + .title),
    (.groups[] | .rules[] | "prefix_rule(pattern=" + (.pattern|@json) + ", decision=\"" + .decision + "\")")
  ' "$data")"

  dev_kit_codex_render_template "$templ_dir/rules.tmpl" "$out_dir/rules/default.rules" \
    RULES_BODY "$body"
}

dev_kit_codex_render_skill() {
  local data="$1"
  local out_dir="$2"
  local templ_dir=""
  local schema_dir=""
  templ_dir="$(dev_kit_codex_templates_dir)"
  schema_dir="$(dev_kit_codex_schemas_dir)"

  dev_kit_codex_validate_required "$schema_dir/skill.schema.json" "$data"
  local name desc body
  name="$(jq -r '.name' "$data")"
  desc="$(jq -r '.description' "$data")"
  body="$(jq -r '
    .sections[] |
    ("## " + .title + "\n")
    + (if (.lines|length? > 0) then (.lines|map(. + "\n")|add) else "" end)
    + (if (.bullets|length? > 0) then (.bullets|map("- " + . + "\n")|add) else "" end)
    + "\n"
  ' "$data")"

  mkdir -p "$out_dir/skills/$name"
  dev_kit_codex_render_template "$templ_dir/skill.md.tmpl" "$out_dir/skills/$name/SKILL.md" \
    SKILL_NAME "$name" \
    SKILL_DESCRIPTION "$desc" \
    SKILL_BODY "$body"
}

dev_kit_codex_render_skills() {
  local out_dir="$1"
  local data_dir=""
  data_dir="$(dev_kit_codex_data_dir)"
  local file=""
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    dev_kit_codex_render_skill "$file" "$out_dir"
  done < <(find "$data_dir/skills" -type f -name '*.json' | sort)
}

dev_kit_codex_render_all() {
  local out_dir="$1"
  dev_kit_codex_require_jq
  mkdir -p "$out_dir/rules" "$out_dir/skills"
  dev_kit_codex_render_agents "$out_dir"
  dev_kit_codex_render_config "$out_dir"
  dev_kit_codex_render_rules "$out_dir"
  dev_kit_codex_render_skills "$out_dir"
  dev_kit_codex_apply_placeholders "$out_dir/AGENTS.md" "$out_dir/AGENTS.md"
  dev_kit_codex_apply_placeholders "$out_dir/config.toml" "$out_dir/config.toml"
  dev_kit_codex_apply_placeholders "$out_dir/rules/default.rules" "$out_dir/rules/default.rules"
  local file=""
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    dev_kit_codex_apply_placeholders "$file" "$file"
  done < <(find "$out_dir/skills" -type f -name 'SKILL.md')
}

dev_kit_codex_plan_item() {
  local path="$1"
  local out=""
  out="$(mktemp -d)"
  dev_kit_codex_render_all "$out"
  local out_path="$out/$path"
  if [ ! -e "$out_path" ]; then
    echo "Missing rendered path: $path" >&2
    rm -rf "$out"
    exit 1
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
  local integration=""
  local dst=""
  integration="$(dev_kit_codex_integration_dir)"
  dst="$(dev_kit_codex_dst_dir)"

  case "$sub" in
    status|"")
      echo "integration: $integration"
      echo "data: $(dev_kit_codex_data_dir)"
      echo "schemas: $(dev_kit_codex_schemas_dir)"
      echo "templates: $(dev_kit_codex_templates_dir)"
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
        local dst_item="$dst/$item"
        if [ -e "$dst_item" ]; then
          printf "target/%s: present\n" "$item"
        else
          printf "target/%s: missing\n" "$item"
        fi
      done < <(dev_kit_codex_managed_items)
      ;;
    apply)
      if [ ! -d "$(dev_kit_codex_data_dir)" ]; then
        echo "Missing data directory: $(dev_kit_codex_data_dir)" >&2
        exit 1
      fi
      if [ ! -d "$(dev_kit_codex_schemas_dir)" ]; then
        echo "Missing schemas directory: $(dev_kit_codex_schemas_dir)" >&2
        exit 1
      fi
      if [ ! -d "$(dev_kit_codex_templates_dir)" ]; then
        echo "Missing templates directory: $(dev_kit_codex_templates_dir)" >&2
        exit 1
      fi
      mkdir -p "$dst"
      local rendered=""
      rendered="$(mktemp -d)"
      dev_kit_codex_render_all "$rendered"
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
        local src_item="$rendered/$item"
        local dst_item="$dst/$item"
        if [ -e "$src_item" ]; then
          dev_kit_codex_clear_path "$dst_item"
          cp -R "$src_item" "$dst_item"
          echo "Applied: $item"
        fi
      done < <(dev_kit_codex_managed_items)
      rm -rf "$rendered"
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
          dev_kit_codex_clear_path "$dst_item"
          cp -R "$src_item" "$dst_item"
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
  apply    Render src/ai/data with Codex schemas/templates -> ~/.codex
  config   Render a planned file/dir from src/ai/data + src/ai/integrations/codex
  compare  Compare planned output vs ~/.codex
  restore  Restore the latest backup to ~/.codex

Examples:
  dev.kit codex config --plan --path=skills/dev-kit-prompt
  dev.kit codex compare --path=skills/dev-kit-prompt
CODEX_USAGE
      ;;
    *)
      echo "Unknown codex command: $sub" >&2
      echo "Run: dev.kit codex --help" >&2
      exit 1
      ;;
  esac
}
