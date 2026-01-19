#!/bin/bash

# dev-kit session init
if [ -n "${DEV_KIT_DISABLE:-}" ]; then
  return 0
fi

export DEV_KIT_CONFIG="$HOME/.engineering/dev-kit/config.env"

if command -v dev-kit >/dev/null 2>&1; then
  dev-kit init >/dev/null 2>&1 || true
fi
