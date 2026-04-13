#!/usr/bin/env bash

source scripts/lib.sh

try_unset_cursor_vars() {
  try_unset hot_x hot_y aliases asset asset_name asset_flip asset_flop \
    asset_delay asset_frames asset_rotate
}

get_built_asset_name() {
  if [[ -v asset ]]; then
    echo "$asset"
  elif [[ -v asset_name ]]; then
    local final="$asset_name"

    [[ -v asset_flip ]] && final+='-flipped'
    [[ -v asset_flop ]] && final+='-flopped'
    [[ -v asset_rotate ]] && final+="-rotated-$asset_rotate"
    [[ -v asset_frame ]] && final+="-$asset_frame"

    echo "$final"
  else
    echo "$name"
  fi
}

build_assets() {
  push_debug_scope 'build_assets'

  if [[ "$THEME" == 'default' ]]; then
    debug "copying '$ASSET_PATH' to '$BUILD_ASSET_PATH'"
    cp -r "$ASSET_PATH" "$BUILD_ASSET_PATH"
  else
    debug "creating '$BUILD_ASSET_PATH' directory"
    mkdir -p "$BUILD_ASSET_PATH"

    jq_config_as_vars '.themes.default'

    local default_primary=$primary
    local default_secondary=$secondary
    local default_border=$border

    jq_config_as_vars ".themes.\"$THEME\""

    for asset in $(try_cd "$ASSET_PATH" && echo *); do
      debug "applying theme to '$asset'"
      magick "$ASSET_PATH/$asset" \
        -fill "$primary" -opaque "$default_primary" \
        -fill "$secondary" -opaque "$default_secondary" \
        -fill "$border" -opaque "$default_border" \
        "$BUILD_ASSET_PATH/$asset"
    done

    unset primary secondary border
  fi

  try_cd "$BUILD_ASSET_PATH"

  while read -r name; do
    jq_config_as_vars ".cursors.\"$name\""

    if [[ -v asset ]]; then
      debug "symlinking '$name' to target '$asset'"
      ln -rs "$asset.png" "$name.png"
    elif [[ -v asset_name ]]; then
      local outname
      outname=$(get_built_asset_name)

      local magick_args=("$asset_name.png")
      [[ -v asset_flip ]] && magick_args+=(-flip)
      [[ -v asset_flop ]] && magick_args+=(-flop)
      [[ -v asset_rotate ]] && magick_args+=(-rotate "$asset_rotate")
      magick_args+=("$outname.png")

      debug "building '$outname.png'"
      magick "${magick_args[@]}"

      if [[ -v asset_delay ]] && [[ -v asset_frames ]]; then
        debug "cutting asset into frames"
        magick "$outname.png" -crop "1x$(
          magick identify -format "%[fx:h/$ASSET_SIZE]\n" "$outname.png"
        )@" +repage +adjoin "$outname-%d.png"
      fi
    fi

    try_unset_cursor_vars
  done < <(jq_config -r \
    '.cursors | map_values(select(.asset or .asset_name)) | keys[]')

  try_cd "$OLDPWD"
  pop_debug_scope
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
    local scaled_asset_path="${BUILD_ASSET_PATH}_x$scale"

    mkdir -p "$scaled_asset_path"

    _build() {
      local built_asset_name
      built_asset_name=$(get_built_asset_name)

      local final_asset_name="$name${asset_frame:+"-$asset_frame"}"

      local srcfile="$BUILD_ASSET_PATH/$built_asset_name.png"
      local outfile="$scaled_asset_path/$final_asset_name.png"

      cursor_config+=("$scaled_size $scaled_hot_x $scaled_hot_y $outfile \
        ${asset_delay:+" $asset_delay"}")

      if [[ "$scale" == '1' ]]; then
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
      "$(jq_entry 'filename' "$(quote "$final_asset_name.svg")")"
      "$(jq_entry 'hotspot_x' "$hot_x")"
      "$(jq_entry 'hotspot_y' "$hot_y")"
      "$(jq_entry 'nominal_size' "$ASSET_SIZE")"
    )

    if [[ -v asset_delay ]]; then
      entries+=("$(jq_entry 'delay' "$asset_delay")")
    fi

    pixel-to-svg -O "$cursor_path/$final_asset_name.svg" \
      "$BUILD_ASSET_PATH/$built_asset_name.png"

    concat_jq_entries "${entries[@]}"
  }

  local jq_input jq_operation

  if [[ -v asset_frames ]]; then
    local frame_entries=()

    for asset_frame in "${asset_frames[@]}"; do
      frame_entries+=("$(_build)")
    done

    jq_input=$(concat_jq_entries "${frame_entries[@]}")
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
    debug "building '$name' cursor"

    jq_config_as_vars ".cursors.\"$name\""

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
  done < <(jq_config -r '.cursors | keys[]')

  pop_debug_scope
}

main() {
  push_debug_scope 'main'

  load_config

  if [[ -e "$BUILD_PATH" ]]; then
    debug 'cleaning build path'
    rm -rf "$BUILD_PATH"
  fi

  debug "creating '$BUILD_PATH' directory"
  mkdir -p "$BUILD_PATH"

  debug 'building assets'
  build_assets

  debug 'building cursors'
  build_cursors

  pop_debug_scope
}

main
