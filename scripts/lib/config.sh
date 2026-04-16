#!/usr/bin/env bash

export LIB_CONFIG_SOURCED=1

[[ ! -v LIB_UTILS_SOURCED ]] && source scripts/lib/utils.sh

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
