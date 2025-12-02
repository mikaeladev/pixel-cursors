#!/usr/bin/env bash

ASSET_SIZE=12

source scripts/functions.sh

mkThemedAssets() {
  if [[ $(echo "$themes" | jq -r keys[]) != *"$theme"* ]]; then
    fail "Invalid colour theme: '${theme}'"
  fi

  if [ "${theme}" != default ]; then for asset in assets/*; do
    recolourAsset \
      "$(echo "$themes" | jq -r .default)" \
      "$(echo "$themes" | jq -r ".${theme}")" \
      "$asset" "build/${asset}"
  done; else
    cp -r assets build
  fi
}

mkXCursor() {
  for scale in "${scales[@]}"; do
    local scaledSize=$((ASSET_SIZE * scale))
    local scaledHotX=$((hotX * scale))
    local scaledHotY=$((hotY * scale))

    local buildDir="build/${scaledSize}x${scaledSize}"
    local configFile="build/configs/${name}.cursor"

    mkXCursorFiles() {
      magick "build/assets/${1}.png" -scale "${scale}00%" "${buildDir}/${1}.png"
      echo "${scaledSize} ${scaledHotX} ${scaledHotY} ${buildDir}/${1}.png ${3}" >>"${configFile}"
    }

    if ((${#delays[@]})); then for i in "${!delays[@]}"; do
      mkXCursorFiles "${name}-${i}" "${delays[$i]}"
    done; else
      mkXCursorFiles "$name"
    fi
  done

  xcursorgen "${configFile}" "dist/cursors/${name}"
}

mkScalableCursor() {
  local distDir="dist/cursors_scalable/${name}"
  local dataArr=()

  mkScalableCursorFiles() {
    local data

    data=$(printf \
      '{ "filename": "%s", "hotspot_x": %s, "hotspot_y": %s, "nominal_size": %s }' \
      "${1}.svg" "$hotX" "$hotY" "$ASSET_SIZE")

    [ "$2" ] && data="$(jq -nr "${data} + { \"delay\": ${2} }")"

    dataArr+=("$data")
    pixels2svg "build/assets/${1}.png" >"${distDir}/${1}.svg"
  }

  mkdir "$distDir"

  if ((${#delays[@]})); then for i in "${!delays[@]}"; do
    mkScalableCursorFiles "${name}-${i}" "${delays[$i]}"
  done; else
    mkScalableCursorFiles "$name"
  fi

  echo "[$(joinBy , "${dataArr[@]}")]" | jq -r >"${distDir}/metadata.json"
}

main() {
  loadConfig

  rm -rf build dist

  mkdir build build/configs build/assets dist dist/cursors dist/cursors_scalable

  for scale in "${scales[@]}"; do
    local scaledSize=$((ASSET_SIZE * scale))
    mkdir "build/${scaledSize}x${scaledSize}"
  done

  mkThemedAssets

  readarray -t names <<<"$(echo "${cursors}" | jq -r keys[])"

  for name in "${names[@]}"; do
    hotX=$(echo "$cursors" | jq -r ".[\"${name}\"].hot_x")
    hotY=$(echo "$cursors" | jq -r ".[\"${name}\"].hot_y")
    delays=$(echo "$cursors" | jq -r ".[\"${name}\"].delays")
    aliases=$(echo "$cursors" | jq -r ".[\"${name}\"].aliases")

    if [ "$delays" != null ]; then
      readarray -t delays <<<"$(echo "$delays" | jq -r .[])"
    else delays=(); fi

    if [ "$aliases" != null ]; then
      readarray -t aliases <<<"$(echo "$aliases" | jq -r .[])"
    else aliases=(); fi

    echo "building '${name}' cursor..."

    mkXCursor
    mkScalableCursor

    if ((${#aliases[@]})); then for alias in "${aliases[@]}"; do
      ln -sr -T "dist/cursors/${name}" "dist/cursors/${alias}"
      ln -sr -T "dist/cursors_scalable/${name}" "dist/cursors_scalable/${alias}"
    done; fi
  done

  printf '%s\n' \
    "[Icon Theme]" \
    "Name=$(echo "$metadata" | jq -r .name)" \
    "Comment=$(echo "$metadata" | jq -r .comment)" \
    "Inherits=$(echo "$metadata" | jq -r .inherits)" \
    >dist/index.theme
}

# TODO: impl proper args handling
theme="${1-default}"
scales=(1 2 3 4 5 6)

main
