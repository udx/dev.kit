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
  printf "%s\n" "AGENTS.md" "config.toml" "rules"
}

dev_kit_codex_managed_skill_prefix() {
  printf "%s" "dev-kit-"
}

dev_kit_codex_list_managed_skill_names() {
  local root_dir="$1"
  local skills_dir="$root_dir/skills"
  local prefix=""
  prefix="$(dev_kit_codex_managed_skill_prefix)"
  [ -d "$skills_dir" ] || return 0

  find "$skills_dir" -mindepth 1 -maxdepth 1 -name "${prefix}*" -exec basename {} \; | sort
}

dev_kit_codex_backup_managed_skills() {
  local dst_root="$1"
  local backup_dir="$2"
  local name=""
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    mkdir -p "$backup_dir/skills"
    cp -R "$dst_root/skills/$name" "$backup_dir/skills/$name"
  done < <(dev_kit_codex_list_managed_skill_names "$dst_root")
}

dev_kit_codex_apply_managed_skills() {
  local rendered_root="$1"
  local dst_root="$2"
  local name=""

  mkdir -p "$dst_root/skills"

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    dev_kit_codex_clear_path "$dst_root/skills/$name"
  done < <(dev_kit_codex_list_managed_skill_names "$dst_root")

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    cp -R "$rendered_root/skills/$name" "$dst_root/skills/$name"
    echo "Applied: skills/$name"
  done < <(dev_kit_codex_list_managed_skill_names "$rendered_root")
}

dev_kit_codex_restore_managed_skills() {
  local backup_root="$1"
  local dst_root="$2"
  local name=""

  mkdir -p "$dst_root/skills"

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    dev_kit_codex_clear_path "$dst_root/skills/$name"
  done < <(dev_kit_codex_list_managed_skill_names "$dst_root")

  while IFS= read -r name; do
    [ -z "$name" ] && continue
    cp -R "$backup_root/skills/$name" "$dst_root/skills/$name"
    echo "Restored: skills/$name"
  done < <(dev_kit_codex_list_managed_skill_names "$backup_root")
}

dev_kit_codex_copy_managed_skills_view() {
  local src_root="$1"
  local out_dir="$2"
  local name=""
  mkdir -p "$out_dir"
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    if [ -d "$src_root/skills/$name" ]; then
      cp -R "$src_root/skills/$name" "$out_dir/$name"
    fi
  done < <(dev_kit_codex_list_managed_skill_names "$src_root")
}

dev_kit_codex_backup_dir() {
  local base=""
  base="$(dev_kit_codex_dst_dir)"
  echo "$base/.backup/dev.kit"
}

dev_kit_codex_new_backup_dir() {
  local base=""
  local stamp=""
  local candidate=""
  local i=0
  base="$(dev_kit_codex_backup_dir)"
  stamp="$(date +%Y%m%d%H%M%S)"
  while :; do
    if [ "$i" -eq 0 ]; then
      candidate="$base/$stamp"
    else
      candidate="$base/${stamp}-${i}"
    fi
    if mkdir "$candidate" 2>/dev/null; then
      printf "%s" "$candidate"
      return 0
    fi
    i=$((i + 1))
  done
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
  local data_dir=""
  templ_dir="$(dev_kit_codex_templates_dir)"
  schema_dir="$(dev_kit_codex_schemas_dir)"
  data_dir="$(dev_kit_codex_data_dir)"

  dev_kit_codex_validate_required "$schema_dir/skill.schema.json" "$data"
  local name desc body pack_rel pack_dir
  name="$(jq -r '.name' "$data")"
  desc="$(jq -r '.description' "$data")"
  pack_rel="$(jq -r '.pack_dir // empty' "$data")"
  pack_dir=""

  if [ -n "$pack_rel" ]; then
    if [[ "$pack_rel" = /* ]]; then
      pack_dir="$pack_rel"
    else
      pack_dir="$data_dir/$pack_rel"
    fi
  elif [ -d "$data_dir/skill-packs/$name" ]; then
    pack_dir="$data_dir/skill-packs/$name"
  fi

  body="$(jq -r '
    .sections[] |
    ("## " + .title + "\n")
    + (if (.lines|length? > 0) then (.lines|map(. + "\n")|add) else "" end)
    + (if (.bullets|length? > 0) then (.bullets|map("- " + . + "\n")|add) else "" end)
    + "\n"
  ' "$data")"

  mkdir -p "$out_dir/skills/$name"

  if [ -n "$pack_dir" ]; then
    if [ ! -d "$pack_dir" ]; then
      echo "Missing pack_dir for skill '$name': $pack_dir" >&2
      exit 1
    fi
    cp -R "$pack_dir/." "$out_dir/skills/$name"
  fi

  if [ ! -f "$out_dir/skills/$name/SKILL.md" ]; then
    dev_kit_codex_render_template "$templ_dir/skill.md.tmpl" "$out_dir/skills/$name/SKILL.md" \
      SKILL_NAME "$name" \
      SKILL_DESCRIPTION "$desc" \
      SKILL_BODY "$body"
  fi
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

dev_kit_codex_target_to_path() {
  local target="$1"
  case "$target" in
    agents) printf "%s" "AGENTS.md" ;;
    config) printf "%s" "config.toml" ;;
    rules) printf "%s" "rules" ;;
    skills) printf "%s" "skills" ;;
    all) printf "%s" "__all__" ;;
    *)
      echo "Unsupported codex target: $target. Allowed: agents, config, rules, skills, all." >&2
      return 1
      ;;
  esac
}

dev_kit_codex_backup_item() {
  local dst_root="$1"
  local backup_dir="$2"
  local rel_path="$3"
  local dst_item="$dst_root/$rel_path"
  if [ -e "$dst_item" ]; then
    mkdir -p "$backup_dir/$(dirname "$rel_path")"
    cp -R "$dst_item" "$backup_dir/$rel_path"
  fi
}

dev_kit_codex_apply_item() {
  local rendered_root="$1"
  local dst_root="$2"
  local rel_path="$3"
  local src_item="$rendered_root/$rel_path"
  local dst_item="$dst_root/$rel_path"
  if [ ! -e "$src_item" ]; then
    echo "Missing rendered path: $rel_path" >&2
    return 1
  fi
  dev_kit_codex_clear_path "$dst_item"
  cp -R "$src_item" "$dst_item"
  echo "Applied: $rel_path"
}

dev_kit_codex_plan_target() {
  local target="$1"
  local path=""
  path="$(dev_kit_codex_target_to_path "$target")"

  if [ "$path" = "__all__" ]; then
    dev_kit_codex_print_plan "AGENTS.md"
    printf "\n"
    dev_kit_codex_print_plan "config.toml"
    printf "\n"
    dev_kit_codex_print_plan "rules"
    printf "\n"
    dev_kit_codex_print_plan "skills"
    return 0
  fi

  dev_kit_codex_print_plan "$path"
}

dev_kit_codex_apply_target() {
  local target="$1"
  local dst=""
  local path=""
  local rendered=""
  local backup_base=""
  local backup_dir=""

  dst="$(dev_kit_codex_dst_dir)"
  path="$(dev_kit_codex_target_to_path "$target")" || return 1

  if [ ! -d "$(dev_kit_codex_data_dir)" ]; then
    echo "Missing data directory: $(dev_kit_codex_data_dir)" >&2
    return 1
  fi
  if [ ! -d "$(dev_kit_codex_schemas_dir)" ]; then
    echo "Missing schemas directory: $(dev_kit_codex_schemas_dir)" >&2
    return 1
  fi
  if [ ! -d "$(dev_kit_codex_templates_dir)" ]; then
    echo "Missing templates directory: $(dev_kit_codex_templates_dir)" >&2
    return 1
  fi

  mkdir -p "$dst"
  rendered="$(mktemp -d)"
  dev_kit_codex_render_all "$rendered"

  backup_base="$(dev_kit_codex_backup_dir)"
  mkdir -p "$backup_base"
  backup_dir="$(dev_kit_codex_new_backup_dir)"

  if [ "$path" = "__all__" ]; then
    dev_kit_codex_backup_item "$dst" "$backup_dir" "AGENTS.md"
    dev_kit_codex_backup_item "$dst" "$backup_dir" "config.toml"
    dev_kit_codex_backup_item "$dst" "$backup_dir" "rules"
    dev_kit_codex_backup_managed_skills "$dst" "$backup_dir"

    dev_kit_codex_apply_item "$rendered" "$dst" "AGENTS.md" || {
      rm -rf "$rendered"
      return 1
    }
    dev_kit_codex_apply_item "$rendered" "$dst" "config.toml" || {
      rm -rf "$rendered"
      return 1
    }
    dev_kit_codex_apply_item "$rendered" "$dst" "rules" || {
      rm -rf "$rendered"
      return 1
    }
    dev_kit_codex_apply_managed_skills "$rendered" "$dst"
  elif [ "$path" = "skills" ]; then
    dev_kit_codex_backup_managed_skills "$dst" "$backup_dir"
    dev_kit_codex_apply_managed_skills "$rendered" "$dst"
  else
    dev_kit_codex_backup_item "$dst" "$backup_dir" "$path"
    dev_kit_codex_apply_item "$rendered" "$dst" "$path" || {
      rm -rf "$rendered"
      return 1
    }
  fi

  rm -rf "$rendered"
  echo "Backup: $backup_dir"
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
      echo "managed_skill_prefix: $(dev_kit_codex_managed_skill_prefix)"
      echo "targets: agents, config, rules, skills, all"
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
      local managed_skills=""
      managed_skills="$(dev_kit_codex_list_managed_skill_names "$dst" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
      if [ -n "$managed_skills" ]; then
        echo "target/skills (managed): $managed_skills"
      else
        echo "target/skills (managed): none"
      fi
      ;;
    apply)
      dev_kit_codex_apply_target "all"
      ;;
    agents|rules|skills|all|toml|config-file)
      local target="$sub"
      local mode=""
      shift || true
      while [ $# -gt 0 ]; do
        case "$1" in
          --plan)
            mode="plan"
            ;;
          --apply)
            mode="apply"
            ;;
          *)
            echo "Unknown codex $sub option: $1" >&2
            exit 1
            ;;
        esac
        shift || true
      done
      if [ -z "$mode" ]; then
        echo "codex $sub requires --plan or --apply" >&2
        exit 1
      fi
      case "$target" in
        toml|config-file) target="config" ;;
      esac
      if [ "$mode" = "plan" ]; then
        dev_kit_codex_plan_target "$target"
      else
        dev_kit_codex_apply_target "$target"
      fi
      ;;
    config)
      local target=""
      local mode=""
      local path=""
      shift || true
      if [ $# -gt 0 ] && [[ "${1:-}" != --* ]]; then
        target="$1"
        shift || true
      fi
      while [ $# -gt 0 ]; do
        case "$1" in
          --plan)
            mode="plan"
            ;;
          --apply)
            mode="apply"
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
      if [ -z "$mode" ]; then
        echo "codex config requires --plan or --apply" >&2
        exit 1
      fi
      if [ -n "$path" ] && [ "$mode" = "apply" ]; then
        echo "codex config --apply does not support --path; use a target (agents|config|rules|skills|all)." >&2
        exit 1
      fi

      if [ -n "$path" ]; then
        dev_kit_codex_print_plan "$path"
        return 0
      fi

      if [ -z "$target" ]; then
        if [ "$mode" = "apply" ]; then
          target="all"
        else
          target="config"
        fi
      fi

      if [ "$mode" = "plan" ]; then
        dev_kit_codex_plan_target "$target"
      else
        dev_kit_codex_apply_target "$target"
      fi
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
      if [ "$path" = "skills" ]; then
        local managed_out=""
        local managed_dst=""
        managed_out="$(mktemp -d)"
        managed_dst="$(mktemp -d)"
        dev_kit_codex_copy_managed_skills_view "$(dirname "$out_path")" "$managed_out"
        dev_kit_codex_copy_managed_skills_view "$dst" "$managed_dst"
        diff -ru "$managed_out" "$managed_dst" || true
        rm -rf "$managed_out" "$managed_dst"
      elif [ -d "$out_path" ] || [ -d "$dst_path" ]; then
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
      dev_kit_codex_restore_managed_skills "$backup_dir" "$dst"
      echo "Restored from: $backup_dir"
      ;;
    help|-h|--help)
      cat <<'CODEX_USAGE'
Usage: dev.kit codex <command>

Commands:
  status   Show Codex integration state/settings (default)
  apply    Apply all managed codex artifacts (legacy alias of: codex config all --apply)
  config   Plan/apply a target: agents|config|rules|skills|all
  agents   Shorthand: codex config agents --plan|--apply
  rules    Shorthand: codex config rules --plan|--apply
  skills   Shorthand: codex config skills --plan|--apply
  all      Shorthand: codex config all --plan|--apply
  toml     Shorthand: codex config config --plan|--apply
  compare  Compare planned output vs ~/.codex
  restore  Restore the latest backup to ~/.codex

Examples:
  dev.kit codex
  dev.kit codex skills --plan
  dev.kit codex config rules --plan
  dev.kit codex config skills --apply
  dev.kit codex config all --apply
  dev.kit codex config --plan --path=skills/dev-kit-prompt/SKILL.md
CODEX_USAGE
      ;;
    *)
      echo "Unknown codex command: $sub" >&2
      echo "Run: dev.kit codex --help" >&2
      exit 1
      ;;
  esac
}
