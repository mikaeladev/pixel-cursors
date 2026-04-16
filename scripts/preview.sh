#!/usr/bin/env bash

set -euo pipefail

source scripts/lib/assets.sh
source scripts/lib/config.sh
source scripts/lib/utils.sh

trap 'exit_trap' 'EXIT'

main() {
  push_debug_scope 'main'

  # todo!

  pop_debug_scope
}

main
