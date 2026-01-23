#!/bin/bash

workflow_main() {
  shift || true

  
  echo "Execute workflow:" $(echo "$1" | jq -c '.')
}
