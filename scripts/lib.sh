#!/usr/bin/env bash

: "${ASSET_PATH:=assets}"
: "${ASSET_SIZE:=12}"
: "${ASSET_MAX_SCALE:=6}"

: "${BUILD_PATH:=build}"
: "${BUILD_ASSET_PATH:=$BUILD_PATH/assets}"

: "${THEME:=${1:-default}}"

fail() {
  >&2 echo "fatal: $*" >&2
  exit 1
}

concat() {
  local IFS="$1"
  shift
  echo "$*"
}

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
  if [[ -v DEBUG ]] || [[ -v VERBOSE ]]; then
    >&2 echo "${DEBUG_SCOPE:+${DEBUG_SCOPE[-1]}: }$*"
  fi
}

log() {
  if [[ ! -v QUIET ]]; then
    >&2 echo "$@"
  fi
}

try_cd() {
  cd "$@" || fail "cd failed"
}

try_unset() {
  unset -v "$@" &>/dev/null || true
}

quote() {
  echo "\"$1\""
}

CONFIG_ROOT=$(pwd)

load_config() {
  push_debug_scope 'load_config'
  
  if [[ ! -v CONFIG ]]; then
    debug "reading '$CONFIG_ROOT/config.toml'"
    CONFIG=$(toml get "$CONFIG_ROOT/config.toml" '.')
  fi
  
  pop_debug_scope
}

jq_config() {
  load_config
  echo "$CONFIG" | jq "$@"
}

IFS='' read -r -d '' JQ_CONFIG_AS_VARS_OP <<"EOF"
def to_value:
  if type == "array" then
    "(\(map(to_value) | join(" ")))"
  else
    if type == "string" then
      "'\(.)'"
    else
      if type == "boolean" then
        if . == true then 1 else 0 end
      else
        tostring
      end
    end
  end;

def to_vars:
  to_entries | map(
    if (.value | type == "object") then
      "\(.key)_\(.value | to_vars)"
    else
      "\(.key)=\(.value | to_value)"
    end
  ) | .[];

%s | to_vars
EOF

jq_config_as_vars() {
  push_debug_scope 'jq_config_as_vars'

  debug "reading values at '$1'"
  while IFS= read -r kv; do
    debug "setting '$kv'"
    eval "${kv}"
  done < <(jq_config -r "$(printf "$JQ_CONFIG_AS_VARS_OP" "${1:-.}")")

  pop_debug_scope
}

jq_entry() {
  echo "{ $(quote 'key'): $(quote "$1"), $(quote 'value'): $2 }"
}

concat_jq_entries() {
  echo "[$(concat ',' "$@")]"
}
