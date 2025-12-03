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
      "$asset" "${buildDir}/${asset}"
  done; else
    cp -r assets "${buildDir}"
  fi
}

mkXCursor() {
  for scale in "${scales[@]}"; do
    local scaledSize=$((ASSET_SIZE * scale))
    local scaledHotX=$((hotX * scale))
    local scaledHotY=$((hotY * scale))

    local scaledAssetsDir="${buildDir}/${scaledSize}x${scaledSize}"
    local cursorConfigFile="${buildDir}/configs/${name}.cursor"

    mkXCursorFiles() {
      magick "${buildDir}/assets/${1}.png" -scale "${scale}00%" \
        "${scaledAssetsDir}/${1}.png"

      echo "${scaledSize} ${scaledHotX} ${scaledHotY} ${scaledAssetsDir}/${1}.png ${3}" \
        >>"${cursorConfigFile}"
    }

    if ((${#delays[@]})); then for i in "${!delays[@]}"; do
      mkXCursorFiles "${name}-${i}" "${delays[$i]}"
    done; else
      mkXCursorFiles "$name"
    fi
  done

  xcursorgen "${cursorConfigFile}" "${distDir}/cursors/${name}"
}

mkScalableCursor() {
  local cursorDir="${distDir}/cursors_scalable/${name}"
  local dataArr=()

  mkScalableCursorFiles() {
    local data

    data=$(printf \
      '{ "filename": "%s", "hotspot_x": %s, "hotspot_y": %s, "nominal_size": %s }' \
      "${1}.svg" "$hotX" "$hotY" "$ASSET_SIZE")

    [ "$2" ] && data="$(jq -nr "${data} + { \"delay\": ${2} }")"

    dataArr+=("$data")
    pixels2svg "${buildDir}/assets/${1}.png" >"${cursorDir}/${1}.svg"
  }

  mkdir "$cursorDir"

  if ((${#delays[@]})); then for i in "${!delays[@]}"; do
    mkScalableCursorFiles "${name}-${i}" "${delays[$i]}"
  done; else
    mkScalableCursorFiles "$name"
  fi

  echo "[$(joinBy , "${dataArr[@]}")]" | jq -r >"${cursorDir}/metadata.json"
}

main() {
  loadConfig

  rm -rf "$buildDir" "$distDir"

  mkdir -p "${buildDir}/configs" "${buildDir}/assets" \
    "${distDir}/cursors" "${distDir}/cursors_scalable"

  for scale in "${scales[@]}"; do
    local scaledSize=$((ASSET_SIZE * scale))
    mkdir "${buildDir}/${scaledSize}x${scaledSize}"
  done

  echo "applying '${theme}' theme..."
  mkThemedAssets

  readarray -t names <<<"$(echo "$cursors" | jq -r keys[])"

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

    if ((${#aliases[@]})); then (
      cd "${distDir}" || fail "cd failed"
      for alias in "${aliases[@]}"; do
        ln -sr -T "cursors/${name}" "cursors/${alias}"
        ln -sr -T "cursors_scalable/${name}" "cursors_scalable/${alias}"
      done
    ); fi
  done

  printf '%s\n' \
    "[Icon Theme]" \
    "Name=${theme^} $(echo "$metadata" | jq -r .name)" \
    "Comment=$(echo "$metadata" | jq -r .comment)" \
    "Inherits=$(echo "$metadata" | jq -r .inherits)" \
    >"${distDir}/index.theme"
}

# TODO: impl proper args handling
theme="${1-default}"
scales=(1 2 3 4 5 6)
buildDir="build"
distDir="dist"
distDir="${distDir}/pixel-cursors-${theme}"

main
