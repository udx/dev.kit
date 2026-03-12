#!/usr/bin/env bash

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC1091
. "$REPO_DIR/lib/modules/bootstrap.sh"
dev_kit_bootstrap

case ":$PATH:" in
  *":${DEV_KIT_BIN_DIR}:"*) ;;
  *) export PATH="${DEV_KIT_BIN_DIR}:${PATH}" ;;
esac

if [ -n "${BASH_VERSION:-}" ] && [ -f "${DEV_KIT_HOME}/bin/completions/dev.kit.bash" ]; then
  # shellcheck disable=SC1090
  . "${DEV_KIT_HOME}/bin/completions/dev.kit.bash"
fi

if [ -n "${ZSH_VERSION:-}" ] && [ -f "${DEV_KIT_HOME}/bin/completions/_dev.kit" ]; then
  fpath=("${DEV_KIT_HOME}/bin/completions" $fpath)
  autoload -Uz compinit
  compinit -i
fi

export DEV_KIT_HOME
