#!/usr/bin/env bash

export LIB_UTILS_SOURCED=1

if [[ ! -v DEBUG_SCOPE ]]; then
  DEBUG_SCOPE=()
fi

push_debug_scope() {
  DEBUG_SCOPE+=("$1")
}

pop_debug_scope() {
  unset 'DEBUG_SCOPE[-1]'
}

debug() {
  if [[ $QUIET != '1' ]] && [[ $DEBUG == '1' ]]; then
    echo >&2 "${DEBUG_SCOPE:+${DEBUG_SCOPE[-1]}: }$*"
  fi
}

log() {
  if [[ $QUIET != '1' ]]; then
    if [[ $DEBUG == '1' ]]; then
      echo >&2 "${DEBUG_SCOPE:+${DEBUG_SCOPE[-1]}: }$*"
    else
      echo >&2 "$@"
    fi
  fi
}

fail() {
  echo >&2 "fatal: $*" >&2
  exit 1
}

concat() {
  local IFS="$1"
  shift
  echo "$*"
}

try_clean() {
  if [[ -e $1 ]]; then
    debug "cleaning '$1' directory"
    rm -r "$1" || fail 'clean failed'
  fi
}

try_cd() {
  cd "$@" || fail 'cd failed'
}

try_unset() {
  unset -v "$@" &>/dev/null || true
}

jq_entry() {
  printf '{ "key": "%s", "value": %s }' "$1" "$2"
}

jq_array() {
  echo "[$(concat ',' "$@")]"
}

exit_trap() {
  push_debug_scope 'exit_trap'

  if [[ $BUILD_KEEP != '1' ]]; then
    try_clean "$BUILD_PATH"
  fi

  try_unset \
    LIB_ASSETS_SOURCED \
    LIB_CONFIG_SOURCED \
    LIB_UTILS_SOURCED

  pop_debug_scope
}
