#!/usr/bin/env bash

set -euo pipefail

: "${DEBUG:=0}"
: "${QUIET:=0}"

: "${THEME:=${1:-default}}"

: "${ASSET_SIZE:=12}"
: "${ASSET_MAX_SCALE:=6}"
: "${ASSET_PATH:=assets}"

: "${BUILD_PATH:=build}"
: "${BUILD_KEEP:=$DEBUG}"

: "${DIST_PATH:=dist}"

source scripts/lib/assets.sh
source scripts/lib/config.sh
source scripts/lib/utils.sh

trap 'exit_trap' 'EXIT'

try_unset_cursor_vars() {
  try_unset hot_x hot_y aliases asset asset_name asset_flip asset_flop \
    asset_delay asset_frames asset_rotate
}

build_xorg_cursor() {
  push_debug_scope 'build_xorg_cursor'

  local cursor_config=()
  local cursor_path="$BUILD_PATH/cursors/$name"

  mkdir -p "$(dirname "$cursor_path")"

  for scale in $(seq "$ASSET_MAX_SCALE"); do
    local scaled_size=$((scale * ASSET_SIZE))
    local scaled_hot_x=$((scale * hot_x))
    local scaled_hot_y=$((scale * hot_y))
    local scaled_asset_path="$BUILD_PATH/assets_x$scale"

    mkdir -p "$scaled_asset_path"

    _build() {
      local built_asset_name
      built_asset_name=$(get_built_asset_name)

      local final_asset_name="$name${asset_frame:+"-$asset_frame"}"

      local srcfile="$BUILD_PATH/assets/$built_asset_name.png"
      local outfile="$scaled_asset_path/$final_asset_name.png"

      cursor_config+=("$scaled_size $scaled_hot_x $scaled_hot_y $outfile \
        ${asset_delay:+" $asset_delay"}")

      if [[ $scale == '1' ]]; then
        cp "$srcfile" "$outfile"
      else
        magick "$srcfile" -scale "${scale}00%" "$outfile"
      fi
    }

    if [[ -v asset_frames ]]; then
      for asset_frame in "${asset_frames[@]}"; do _build; done
    else
      _build
    fi
  done

  concat $'\n' "${cursor_config[@]}" | xcursorgen >"$cursor_path"

  pop_debug_scope
}

build_svg_cursor() {
  push_debug_scope 'build_svg_cursor'

  local cursor_path="$BUILD_PATH/cursors_scalable/$name"

  mkdir -p "$cursor_path"

  _build() {
    local built_asset_name
    built_asset_name=$(get_built_asset_name)

    local final_asset_name="$name${asset_frame:+"-$asset_frame"}"

    local entries=(
      "$(jq_entry 'filename' "\"$final_asset_name.svg\"")"
      "$(jq_entry 'hotspot_x' "$hot_x")"
      "$(jq_entry 'hotspot_y' "$hot_y")"
      "$(jq_entry 'nominal_size' "$ASSET_SIZE")"
    )

    if [[ -v asset_delay ]]; then
      entries+=("$(jq_entry 'delay' "$asset_delay")")
    fi

    pixel-to-svg -O "$cursor_path/$final_asset_name.svg" \
      "$BUILD_PATH/assets/$built_asset_name.png"

    jq_array "${entries[@]}"
  }

  local jq_input jq_operation

  if [[ -v asset_frames ]]; then
    local frame_entries=()

    for asset_frame in "${asset_frames[@]}"; do
      frame_entries+=("$(_build)")
    done

    jq_input=$(jq_array "${frame_entries[@]}")
    jq_operation='[.[] | from_entries]'
  else
    jq_input=$(_build)
    jq_operation='from_entries'
  fi

  echo "$jq_input" | jq -r "$jq_operation" >"$cursor_path/metadata.json"

  pop_debug_scope
}

build_cursors() {
  push_debug_scope 'build_cursors'

  while read -r name; do
    log "building '$name' cursor"

    config_jq_as_vars ".cursors.\"$name\""

    build_xorg_cursor
    build_svg_cursor

    if [[ -v aliases ]]; then
      for directory in {cursors,cursors_scalable}; do
        try_cd "$BUILD_PATH/$directory"

        for alias in "${aliases[@]}"; do
          debug "creating symlink '$alias' for '$name' in '$directory'"
          ln -srT "$name" "$alias"
        done

        try_cd "$OLDPWD"
      done
    fi

    try_unset_cursor_vars
  done < <(config_jq -r '.cursors | keys[]')

  pop_debug_scope
}

build_index() {
  push_debug_scope 'build_index'
  config_jq_as_vars '.metadata'

  if [[ $THEME != 'default' ]]; then
    local non_default=1
  fi

  printf '[Icon Theme]\nName=%s\nComment=%s\n' \
    "$name${non_default:+" (${THEME^})"}" \
    "$comment" >"$BUILD_PATH/index.theme"

  try_unset name comment
  pop_debug_scope
}

main() {
  push_debug_scope 'main'

  try_clean "$BUILD_PATH"

  debug "creating '$BUILD_PATH' directory"
  mkdir -p "$BUILD_PATH"

  debug 'reading config'
  config=$(toml get 'config.toml' '.')

  debug 'building assets'
  build_themed_assets
  build_config_assets

  debug 'building cursors'
  build_cursors

  debug 'building index'
  build_index

  try_clean "$DIST_PATH"

  debug "creating '$DIST_PATH' directory"
  mkdir -p "$DIST_PATH"

  debug "moving cursors into '$DIST_PATH'"
  mv "$BUILD_PATH"/{cursors,cursors_scalable,index.theme} "$DIST_PATH"

  pop_debug_scope
}

main
