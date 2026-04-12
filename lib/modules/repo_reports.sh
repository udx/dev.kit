#!/usr/bin/env bash

dev_kit_repo_factor_summary_json() {
  local repo_dir="$1"
  local factor=""
  local status=""
  local first=1

  printf "{"
  while IFS= read -r factor; do
    status="$(dev_kit_repo_factor_status "$repo_dir" "$factor")"
    if [ "$first" -eq 0 ]; then
      printf ","
    fi
    printf '\n    "%s": {' "$factor"
    printf '\n      "status": "%s",' "$status"
    printf '\n      "evidence": '
    dev_kit_repo_factor_evidence_json "$repo_dir" "$factor"
    if dev_kit_repo_factor_entrypoint "$repo_dir" "$factor" >/dev/null 2>&1; then
      printf ',\n      "entrypoint": "%s"\n    }' "$(dev_kit_repo_factor_entrypoint "$repo_dir" "$factor")"
    else
      printf '\n    }'
    fi
    first=0
  done <<EOF
$(dev_kit_repo_factor_ids)
EOF
  printf '\n  }'
}

dev_kit_repo_agent_contract_text() {
  local repo_dir="$1"

  printf '%s\n' "Use dev.kit JSON output as the machine contract: dev.kit --json, dev.kit repo --json, dev.kit agent --json."
  dev_kit_practice_message_list "standard-repo-first" "strict-agent-boundary" | sed -n '1,2p'

  if [ -f "$repo_dir/AGENTS.md" ]; then
    printf '%s\n' "AGENTS.md exists; treat it as a local agent override after repo-native refs, not as the primary repo contract."
  else
    printf '%s\n' "AGENTS.md is optional. If a local provider-agnostic agent note is needed, keep it small and never let it replace repo-native sources."
  fi

  printf '%s\n' "Do not create parallel agent-only state when repo files such as TODO.md, refs.md, README, docs, and workflows already carry the same context."
}

dev_kit_repo_agent_contract_json() {
  dev_kit_repo_agent_contract_text "$1" | dev_kit_lines_to_json_array
}
