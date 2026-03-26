#!/usr/bin/env bash

DEV_KIT_REPO_CONTEXT_SUBDIR=".udx/dev.kit"
DEV_KIT_REPO_CONTEXT_LEGACY_NOTES_DIR=".tmp/review-notes"
DEV_KIT_REPO_CONTEXT_TODO_TEMPLATE="saved-context-todo.md"
DEV_KIT_REPO_CONTEXT_SUMMARY_TEMPLATE="saved-context-summary.md"
DEV_KIT_REPO_CONTEXT_REFS_TEMPLATE="saved-context-refs.md"
DEV_KIT_REPO_CONTEXT_LEGACY_NOTES_TEMPLATE="saved-context-legacy-notes.md"
DEV_KIT_REPO_CONTEXT_CACHE_REPO=""
DEV_KIT_REPO_CONTEXT_CACHE_PRIMARY_ARCHETYPE=""
DEV_KIT_REPO_CONTEXT_CACHE_ARCHETYPES=""
DEV_KIT_REPO_CONTEXT_CACHE_FACETS=""
DEV_KIT_REPO_CONTEXT_CACHE_PRIMARY_PROFILE=""
DEV_KIT_REPO_CONTEXT_CACHE_PROFILES=""
DEV_KIT_REPO_CONTEXT_CACHE_VERIFY_CMD=""
DEV_KIT_REPO_CONTEXT_CACHE_RUNTIME_CMD=""
DEV_KIT_REPO_CONTEXT_CACHE_BUILD_CMD=""
DEV_KIT_REPO_CONTEXT_CACHE_ADVICE_LINES=""
DEV_KIT_REPO_CONTEXT_CACHE_GUIDANCE_LINES=""
DEV_KIT_REPO_CONTEXT_CACHE_PRIORITY_PATHS=""
DEV_KIT_REPO_CONTEXT_CACHE_SAVED_CONTEXT_PATHS=""
DEV_KIT_REPO_CONTEXT_CACHE_LEGACY_NOTES_SECTION=""

dev_kit_repo_context_dir() {
  local repo_dir="${1:-$(pwd)}"
  printf "%s" "$repo_dir/$DEV_KIT_REPO_CONTEXT_SUBDIR"
}

dev_kit_repo_context_file_paths() {
  local repo_dir="${1:-$(pwd)}"
  local context_dir=""
  local file_name=""

  context_dir="$(dev_kit_repo_context_dir "$repo_dir")"

  while IFS= read -r file_name; do
    [ -n "$file_name" ] || continue
    if [ -f "$context_dir/$file_name" ]; then
      printf "./%s/%s\n" "$DEV_KIT_REPO_CONTEXT_SUBDIR" "$file_name"
    fi
  done <<EOF
$(dev_kit_context_list "saved_context_files")
EOF
}

dev_kit_repo_has_saved_context() {
  local repo_dir="${1:-$(pwd)}"
  local file_path=""

  while IFS= read -r file_path; do
    [ -n "$file_path" ] || continue
    return 0
  done <<EOF
$(dev_kit_repo_context_file_paths "$repo_dir")
EOF

  return 1
}

dev_kit_repo_saved_context_files_json() {
  dev_kit_repo_context_file_paths "$1" | dev_kit_lines_to_json_array
}

dev_kit_repo_saved_context_json() {
  local repo_dir="${1:-$(pwd)}"
  local present="false"

  if dev_kit_repo_has_saved_context "$repo_dir"; then
    present="true"
  fi

  printf '{ "present": %s, "files": %s, "reading_order": %s }' \
    "$present" \
    "$(dev_kit_repo_saved_context_files_json "$repo_dir")" \
    "$(dev_kit_repo_saved_context_files_json "$repo_dir")"
}

dev_kit_repo_saved_context_summary_text() {
  local repo_dir="${1:-$(pwd)}"
  local files=""

  if ! dev_kit_repo_has_saved_context "$repo_dir"; then
    return 1
  fi

  files="$(dev_kit_repo_context_file_paths "$repo_dir" | dev_kit_lines_to_csv)"
  printf "%s" "$files"
}

dev_kit_repo_priority_refs() {
  local repo_dir="${1:-$(pwd)}"
  local path=""

  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ -e "$repo_dir/$path" ]; then
      printf "./%s\n" "$path"
    fi
  done <<EOF
$(dev_kit_context_list "priority_paths")
EOF
}

dev_kit_repo_factor_entrypoint_or_unknown() {
  local repo_dir="$1"
  local factor="$2"

  if dev_kit_repo_factor_entrypoint "$repo_dir" "$factor" >/dev/null 2>&1; then
    dev_kit_repo_factor_entrypoint "$repo_dir" "$factor"
    return 0
  fi

  printf "%s" "none detected"
}

dev_kit_lines_to_markdown_bullets() {
  local item=""
  local emitted=0

  while IFS= read -r item || [ -n "$item" ]; do
    [ -n "$item" ] || continue
    printf -- "- %s\n" "$item"
    emitted=1
  done

  if [ "$emitted" -eq 0 ]; then
    printf -- "- none\n"
  fi
}

dev_kit_repo_legacy_notes_section() {
  local repo_dir="$1"
  local note_file=""
  local legacy_notes_body=""

  if [ ! -d "$repo_dir/$DEV_KIT_REPO_CONTEXT_LEGACY_NOTES_DIR" ]; then
    dev_kit_template_render "$DEV_KIT_REPO_CONTEXT_LEGACY_NOTES_TEMPLATE" \
      "legacy_notes_body=- none"
    return 0
  fi

  while IFS= read -r note_file; do
    [ -n "$note_file" ] || continue
    legacy_notes_body="${legacy_notes_body}### $(basename "$note_file")

$(cat "$note_file")

"
  done <<EOF
$(find "$repo_dir/$DEV_KIT_REPO_CONTEXT_LEGACY_NOTES_DIR" -maxdepth 1 -type f -name '*.md' | sort)
EOF

  dev_kit_template_render "$DEV_KIT_REPO_CONTEXT_LEGACY_NOTES_TEMPLATE" \
    "legacy_notes_body=$legacy_notes_body"
}

dev_kit_repo_write_context_file() {
  local repo_dir="$1"
  local context_dir="$2"
  local target_file="$3"
  local template_name="$4"

  dev_kit_repo_prepare_context_values "$repo_dir"

  dev_kit_template_render "$template_name" \
    "repo_dir=$repo_dir" \
    "primary_archetype=$DEV_KIT_REPO_CONTEXT_CACHE_PRIMARY_ARCHETYPE" \
    "archetypes=$DEV_KIT_REPO_CONTEXT_CACHE_ARCHETYPES" \
    "facets=$DEV_KIT_REPO_CONTEXT_CACHE_FACETS" \
    "primary_profile=$DEV_KIT_REPO_CONTEXT_CACHE_PRIMARY_PROFILE" \
    "profiles=$DEV_KIT_REPO_CONTEXT_CACHE_PROFILES" \
    "verify_cmd=$DEV_KIT_REPO_CONTEXT_CACHE_VERIFY_CMD" \
    "runtime_cmd=$DEV_KIT_REPO_CONTEXT_CACHE_RUNTIME_CMD" \
    "build_cmd=$DEV_KIT_REPO_CONTEXT_CACHE_BUILD_CMD" \
    "advice_lines=$DEV_KIT_REPO_CONTEXT_CACHE_ADVICE_LINES" \
    "guidance_lines=$DEV_KIT_REPO_CONTEXT_CACHE_GUIDANCE_LINES" \
    "priority_paths=$DEV_KIT_REPO_CONTEXT_CACHE_PRIORITY_PATHS" \
    "saved_context_paths=$DEV_KIT_REPO_CONTEXT_CACHE_SAVED_CONTEXT_PATHS" \
    "legacy_notes_section=$DEV_KIT_REPO_CONTEXT_CACHE_LEGACY_NOTES_SECTION" \
    > "$context_dir/$target_file"
}

dev_kit_repo_prepare_context_values() {
  local repo_dir="$1"

  if [ "$DEV_KIT_REPO_CONTEXT_CACHE_REPO" = "$repo_dir" ]; then
    return 0
  fi

  DEV_KIT_REPO_CONTEXT_CACHE_REPO="$repo_dir"
  DEV_KIT_REPO_CONTEXT_CACHE_PRIMARY_ARCHETYPE="$(dev_kit_repo_primary_archetype "$repo_dir")"
  DEV_KIT_REPO_CONTEXT_CACHE_ARCHETYPES="$(dev_kit_repo_archetypes_text "$repo_dir")"
  DEV_KIT_REPO_CONTEXT_CACHE_FACETS="$(dev_kit_repo_facets_text "$repo_dir")"
  DEV_KIT_REPO_CONTEXT_CACHE_PRIMARY_PROFILE="$(dev_kit_repo_primary_profile "$repo_dir")"
  DEV_KIT_REPO_CONTEXT_CACHE_PROFILES="$(dev_kit_repo_profiles_text "$repo_dir")"
  DEV_KIT_REPO_CONTEXT_CACHE_VERIFY_CMD="$(dev_kit_repo_factor_entrypoint_or_unknown "$repo_dir" "verification")"
  DEV_KIT_REPO_CONTEXT_CACHE_RUNTIME_CMD="$(dev_kit_repo_factor_entrypoint_or_unknown "$repo_dir" "runtime")"
  DEV_KIT_REPO_CONTEXT_CACHE_BUILD_CMD="$(dev_kit_repo_factor_entrypoint_or_unknown "$repo_dir" "build_release_run")"
  DEV_KIT_REPO_CONTEXT_CACHE_ADVICE_LINES="$(dev_kit_repo_advices "$repo_dir" | sed 's/^advice: //' | dev_kit_lines_to_markdown_bullets)"
  DEV_KIT_REPO_CONTEXT_CACHE_GUIDANCE_LINES="$(dev_kit_repo_agent_guidance_text "$repo_dir" | dev_kit_lines_to_markdown_bullets)"
  DEV_KIT_REPO_CONTEXT_CACHE_PRIORITY_PATHS="$(dev_kit_repo_priority_refs "$repo_dir" | awk '!seen[$0]++' | dev_kit_lines_to_markdown_bullets)"
  DEV_KIT_REPO_CONTEXT_CACHE_SAVED_CONTEXT_PATHS="$(dev_kit_context_list "saved_context_files" | sed "s#^#./$DEV_KIT_REPO_CONTEXT_SUBDIR/#" | dev_kit_lines_to_markdown_bullets)"
  DEV_KIT_REPO_CONTEXT_CACHE_LEGACY_NOTES_SECTION="$(dev_kit_repo_legacy_notes_section "$repo_dir")"
}

dev_kit_repo_write_context_todo() {
  dev_kit_repo_write_context_file "$1" "$2" "todo.md" "$DEV_KIT_REPO_CONTEXT_TODO_TEMPLATE"
}

dev_kit_repo_write_context_summary() {
  dev_kit_repo_write_context_file "$1" "$2" "context.md" "$DEV_KIT_REPO_CONTEXT_SUMMARY_TEMPLATE"
}

dev_kit_repo_write_context_refs() {
  dev_kit_repo_write_context_file "$1" "$2" "refs.md" "$DEV_KIT_REPO_CONTEXT_REFS_TEMPLATE"
}
