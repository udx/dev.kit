#!/bin/bash

codex_main() {
  shift || true

  local codex_env="$REPO_DIR/config/codex.env"
  local rules_path_raw="${DEV_KIT_CODEX_RULES_PATH:-$(config_value "$codex_env" CODEX_RULES_PATH "~/.codex/rules/default.rules")}"
  local config_path_raw="${DEV_KIT_CODEX_CONFIG_PATH:-$(config_value "$codex_env" CODEX_CONFIG_PATH "~/.codex/config.env")}"
  local rules_template_raw="${DEV_KIT_CODEX_RULES_TEMPLATE:-$(config_value "$codex_env" CODEX_RULES_TEMPLATE "src/context/20_config/ai/codex/rules-template.md")}"
  local rules_overrides_raw="${DEV_KIT_CODEX_RULES_OVERRIDES:-$(config_value "$codex_env" CODEX_RULES_OVERRIDES "src/context/20_config/ai/codex/overrides.md")}"
  local rules_sources_raw="${DEV_KIT_CODEX_RULES_SOURCES:-$(config_value "$codex_env" CODEX_RULES_SOURCES "src/context/30_module/ai/rules.md,src/context/30_module/ai/codex/overview.md,src/context/20_config/standards/development-standards.md,src/context/20_config/principles/development-tenets.md,src/context/20_config/user-experience/cli-output.md,src/context/20_config/references/codex_prompting_guide.md,src/context/20_config/ai,src/context/index.md,src/index.md")}"
  local rules_artifact_raw="${DEV_KIT_CODEX_RULES_ARTIFACT:-public/modules/ai/codex/rules.md}"

  local rules_path="$(expand_path "$rules_path_raw")"
  local config_path="$(expand_path "$config_path_raw")"
  local config_path_alt="$(expand_path "${DEV_KIT_CODEX_CONFIG_PATH_ALT:-$HOME/.codex/config.toml}")"
  local rules_template="$(expand_path "$rules_template_raw")"
  local rules_overrides="$(expand_path "$rules_overrides_raw")"
  local rules_sources="$rules_sources_raw"
  local codex_home="$(expand_path "${DEV_KIT_CODEX_HOME:-$HOME/.codex}")"
  local rules_artifact="$(expand_path "$rules_artifact_raw")"

  build_codex_rules() {
    comment_block() {
      sed -e 's/^/# /'
    }

    emit_source_file() {
      local source_file="$1"
      local rel_path="${source_file#"$REPO_DIR/"}"
      local total_lines
      local max_lines=40

      echo ""
      echo "# ${rel_path}"
      case "$source_file" in
        *.json|*.yml|*.yaml)
          echo "# (skipped in rules; see file directly)"
          return
          ;;
      esac

      sed -n "1,${max_lines}p" "$source_file" | comment_block
      total_lines="$(wc -l < "$source_file" | tr -d ' ')"
      if [ "$total_lines" -gt "$max_lines" ]; then
        echo "# ... (truncated; ${total_lines} lines total)"
      fi
    }

    if [ -f "$rules_template" ]; then
      cat "$rules_template"
    else
      cat <<'RULES'
# ~/.codex/rules/default.rules
# Execpolicy rules for Codex CLI (Starlark).
# Docs: https://developers.openai.com/codex/rules
#
# dev.kit Rules (Codex CLI)
#
# Core behavior
# - Do not call `dev.kit -p` from Codex CLI to avoid loops.
# - If dev.kit output is already provided, use it as the source of truth.
# - Prefer dev.kit refs/docs over generic advice.
# - For known workflows, prefer dev.kit commands after user confirmation when the user is already in dev.kit.
#
# Safety
# - Require previews for apply/push/destructive steps.
# - Keep changes small and reversible.
# - Never auto-move secrets; only suggest secure storage options.
#
# -------------------------------------------------------------------
# Prevent dev.kit pipeline loops / self-triggering automation
# -------------------------------------------------------------------
prefix_rule(
    pattern = ["dev.kit", "-p"],
    decision = "forbidden",
    justification = "Avoid dev.kit pipeline loops. Run dev.kit without -p and review output first.",
    match = [
        "dev.kit -p",
        "dev.kit -p build",
        "dev.kit -p deploy --env prod",
    ],
    not_match = [
        "dev.kit",
        "dev.kit capture show",
        "dev.kit help",
    ],
)

# If you also use the long flag, keep this (remove if not applicable).
prefix_rule(
    pattern = ["dev.kit", "--pipeline"],
    decision = "forbidden",
    justification = "Avoid dev.kit pipeline loops. Run dev.kit without --pipeline and review output first.",
    match = [
        "dev.kit --pipeline build",
    ],
)
RULES
    fi
    if [ -f "$rules_overrides" ]; then
      echo ""
      echo "# Overrides"
      echo "#"
      echo "# ${rules_overrides#"$REPO_DIR/"}"
      sed -n '1,160p' "$rules_overrides"
    fi
    echo ""
    echo "# Sources"
    IFS=',' read -r -a sources <<< "$rules_sources"
    for src in "${sources[@]}"; do
      local resolved_src
      resolved_src="$(expand_path "$src")"
      if [ -f "$resolved_src" ]; then
        emit_source_file "$resolved_src"
        continue
      fi
      if [ -d "$resolved_src" ]; then
        while IFS= read -r -d '' source_file; do
          emit_source_file "$source_file"
        done < <(find "$resolved_src" -type f \( -name 'index.md' -o -name 'overview.md' -o -name 'rules-template.md' -o -name 'overrides.md' \) -print0 | sort -z)
      fi
    done
  }

  write_rules_artifact() {
    mkdir -p "$(dirname "$rules_artifact")"
    build_codex_rules > "$rules_artifact"
    echo "Wrote: $rules_artifact"
  }

  resolve_rules_source() {
    if [ -f "$rules_artifact" ]; then
      echo "$rules_artifact"
      return
    fi
    local tmp
    tmp="$(mktemp)"
    build_codex_rules > "$tmp"
    echo "$tmp"
  }

  plan_rules_diff() {
    local src
    src="$(resolve_rules_source)"
    if [ -f "$rules_path" ]; then
      diff -u "$rules_path" "$src" || true
    else
      echo "No existing rules found. New rules preview:"
      cat "$src"
    fi
    if [ "$src" != "$rules_artifact" ]; then
      rm -f "$src"
    fi
  }

  apply_rules_file() {
    local src
    src="$(resolve_rules_source)"
    if [ -f "$rules_path" ]; then
      local backup
      backup="$rules_path.bak.$(date +%Y%m%d%H%M%S)"
      cp "$rules_path" "$backup"
      echo "Backup created: $backup"
    fi
    if [ -t 0 ]; then
      echo "Preview changes:"
      if [ -f "$rules_path" ]; then
        diff -u "$rules_path" "$src" || true
      else
        cat "$src"
      fi
      printf "Apply rules to %s? [y/N] " "$rules_path"
      read -r answer || true
      case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; if [ "$src" != "$rules_artifact" ]; then rm -f "$src"; fi; exit 1 ;;
      esac
    fi
    mkdir -p "$(dirname "$rules_path")"
    cp "$src" "$rules_path"
    if [ "$src" != "$rules_artifact" ]; then
      rm -f "$src"
    fi
    echo "Applied: $rules_path"
  }

  case "${1:-}" in
    --get-rules)
      if [ -f "$rules_path" ]; then
        cat "$rules_path"
      else
        echo "Codex rules file not found: $rules_path" >&2
        exit 1
      fi
      ;;
    config)
      echo "codex_home: $codex_home"
      if [ -f "$config_path" ]; then
        echo "config: $config_path"
        echo ""
        cat "$config_path"
        exit 0
      fi
      if [ -f "$config_path_alt" ]; then
        echo "config: $config_path_alt"
        echo ""
        cat "$config_path_alt"
        exit 0
      fi
      echo "Codex config file not found: $config_path" >&2
      echo "Codex config file not found: $config_path_alt" >&2
      exit 1
      ;;
    rules)
      case "${2:-}" in
        --build)
          write_rules_artifact
          ;;
        --apply)
          apply_rules_file
          ;;
        --plan)
          plan_rules_diff
          ;;
        --show|"" )
          if [ -f "$rules_path" ]; then
            cat "$rules_path"
          else
            echo "Codex rules file not found: $rules_path" >&2
            exit 1
          fi
          ;;
        *)
          echo "Unknown option: $2" >&2
          exit 1
          ;;
      esac
      ;;
    clock)
      shift || true
      "$REPO_DIR/bin/dev-kit" clock "$@" --scope codex --root "$REPO_DIR/.codex/clock"
      ;;
    skills)
      local skills_doc="$REPO_DIR/src/context/30_module/ai/skills.md"
      if [ -f "$skills_doc" ]; then
        cat "$skills_doc"
      else
        echo "Skills doc not found: $skills_doc" >&2
        exit 1
      fi
      ;;
    --plan-rules)
      plan_rules_diff
      ;;
    --build-rules)
      write_rules_artifact
      ;;
    --apply-rules)
      apply_rules_file
      ;;
    "" )
      echo "rules: $rules_path"
      echo "config: $config_path"
      echo "codex_home: $codex_home"
      ;;
    *)
      echo "Unknown option: ${1:-}" >&2
      exit 1
      ;;
  esac
}
