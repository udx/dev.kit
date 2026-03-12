#!/usr/bin/env bash

dev_kit_rule_catalog_path() {
  printf "%s" "$REPO_DIR/src/configs/audit-rules.yaml"
}

dev_kit_rule_field() {
  local rule_id="$1"
  local field_name="$2"
  local catalog_path=""

  catalog_path="$(dev_kit_rule_catalog_path)"

  awk -v rule_id="$rule_id" -v field_name="$field_name" '
    $1 == "config:" {
      in_config = 1
      next
    }

    in_config && $1 == "rules:" {
      in_rules = 1
      next
    }

    in_rules && $1 == "-" && $2 == "id:" {
      current_id = $3
      in_rule = (current_id == rule_id)
      next
    }

    in_rule && $1 == field_name ":" {
      $1 = ""
      sub(/^ /, "")
      print
      exit
    }
  ' "$catalog_path"
}

dev_kit_rule_message() {
  dev_kit_rule_field "$1" "message"
}
