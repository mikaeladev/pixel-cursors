#!/usr/bin/env bash

export LIB_ASSETS_SOURCED=1

[[ ! -v LIB_CONFIG_SOURCED ]] && source scripts/lib/config.sh
[[ ! -v LIB_UTILS_SOURCED ]] && source scripts/lib/utils.sh

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

build_themed_assets() {
  push_debug_scope 'build_themed_assets'

  if [[ $THEME == 'default' ]]; then
    debug "copying '$ASSET_PATH' to '$BUILD_PATH/assets'"
    cp -r "$ASSET_PATH" "$BUILD_PATH/assets"
  else
    debug "creating '$BUILD_PATH/assets' directory"
    mkdir -p "$BUILD_PATH/assets"

    config_jq_as_vars '.themes.default'

    local default_primary=$primary
    local default_secondary=$secondary
    local default_border=$border

    config_jq_as_vars ".themes.\"$THEME\""

    for asset in $(try_cd "$ASSET_PATH" && echo *); do
      debug "applying theme to '$asset'"
      magick "$ASSET_PATH/$asset" \
        -fill "$primary" -opaque "$default_primary" \
        -fill "$secondary" -opaque "$default_secondary" \
        -fill "$border" -opaque "$default_border" \
        "$BUILD_PATH/assets/$asset"
    done

    unset primary secondary border
  fi

  pop_debug_scope
}

build_config_assets() {
  push_debug_scope 'build_config_assets'
  try_cd "$BUILD_PATH/assets"

  while read -r name; do
    config_jq_as_vars ".cursors.\"$name\""

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
        debug "cutting '$outname.png' into frames"
        magick "$outname.png" -crop "1x$(
          magick identify -format "%[fx:h/$ASSET_SIZE]\n" "$outname.png"
        )@" +repage +adjoin "$outname-%d.png"
      fi
    fi

    try_unset_cursor_vars
  done < <(config_jq -r \
    '.cursors | map_values(select(.asset or .asset_name)) | keys[]')

  try_cd "$OLDPWD"
  pop_debug_scope
}
