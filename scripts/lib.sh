#!/usr/bin/env bash

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

clean() {
  if [[ -e $1 ]]; then
    debug "cleaning '$1' directory"
    rm -rf "$1"
  fi
}

try_cd() {
  cd "$@" || fail "cd failed"
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

config_jq() {
  if [[ ! -v config ]]; then
    fail "missing '\$config' variable"
  fi

  echo "$config" | jq "$@"
}

config_jq_as_vars() {
  debug "reading config values at '$1'"
  while IFS= read -r kv; do
    debug "setting '$kv'"
    eval "${kv}"
  done < <(
    # shellcheck disable=SC2059
    config_jq -r "$(printf "$(
      cat <<'EOF'
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
    )" "${1:-.}")"
  )
}
