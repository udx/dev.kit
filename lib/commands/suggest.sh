#!/bin/bash

# @description: Suggest repository improvements and CDE compliance fixes.
# @intent: suggest, improve, cde, compliance, hint, tip
# @objective: Provide actionable advice to improve the repository's engineering experience and CDE standards.
# @usage: dev.kit suggest

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/utils.sh"
fi

if [ -n "${REPO_DIR:-}" ] && [ -f "$REPO_DIR/lib/modules/context_manager.sh" ]; then
  # shellcheck source=/dev/null
  . "$REPO_DIR/lib/modules/context_manager.sh"
fi

dev_kit_cmd_suggest() {
  if command -v ui_header >/dev/null 2>&1; then
    ui_header "Engineering Suggestions"
  else
    echo "--- Engineering Suggestions ---"
  fi

  local suggestions
  suggestions="$(dev_kit_context_suggest_improvements "general repository check")"

  if [ "$suggestions" = "[]" ]; then
    ui_ok "CDE Compliance" "No immediate improvements suggested."
    return
  fi

  echo "$suggestions" | jq -c '.[]' | while read -r sug; do
    local type; type=$(echo "$sug" | jq -r '.type')
    local msg; msg=$(echo "$sug" | jq -r '.message')
    case "$type" in
      doc) ui_info "Documentation" "$msg" ;;
      config) ui_warn "Configuration" "$msg" ;;
      ops) ui_info "Operations" "$msg" ;;
      *) ui_tip "$msg" ;;
    esac
  done

  echo ""
  ui_tip "Run 'dev.kit config detect' to check environment software."
}
