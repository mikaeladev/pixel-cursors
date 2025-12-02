#!/usr/bin/env bash

fail() {
  echo "$@" >&2
  exit 1
}

joinBy() {
  local IFS="$1"
  shift
  echo "$*"
}

loadConfig() {
  config=$(toml get config.toml .)
  metadata=$(echo "$config" | jq -r .metadata)
  themes=$(echo "$config" | jq -r .themes)
  cursors=$(echo "$config" | jq -r .cursors)

  export config metadata themes cursors
}

recolourAsset() {
  local ogTheme=$1
  local rcTheme=$2
  local inputFile=$3
  local outputFile=$4

  local ogPrimaryColour ogSecondaryColour ogBorderColour \
    rcPrimaryColour rcSecondaryColour rcBorderColour

  ogPrimaryColour=$(echo "${ogTheme}" | jq -r .primary)
  ogSecondaryColour=$(echo "${ogTheme}" | jq -r .secondary)
  ogBorderColour=$(echo "${ogTheme}" | jq -r .border)

  rcPrimaryColour=$(echo "${rcTheme}" | jq -r .primary)
  rcSecondaryColour=$(echo "${rcTheme}" | jq -r .secondary)
  rcBorderColour=$(echo "${rcTheme}" | jq -r .border)

  if [[ "${inputFile}" != *.png ]]; then
    fail "recolourAsset: expected a PNG input file"
  fi

  magick "${inputFile}" \
    -fill "${rcPrimaryColour}" -opaque "${ogPrimaryColour}" \
    -fill "${rcSecondaryColour}" -opaque "${ogSecondaryColour}" \
    -fill "${rcBorderColour}" -opaque "${ogBorderColour}" \
    "${outputFile}"
}
