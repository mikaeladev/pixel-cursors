#!/usr/bin/env bash

config=$(toml get ./config.toml .)
metadata=$(echo "${config}" | jq -r .metadata)
themes=$(echo "${config}" | jq -r .themes)
cursors=$(echo "${config}" | jq -r .cursors)

size=12
scales=(1 2 3 4 5 6)
theme=${1-"default"}

if [[ $(echo "${themes}" | jq -r "keys[]") != *"${theme}"* ]]; then
  echo "Invalid colour theme: '${theme}'" >&2
  exit 1
fi

if [ "${theme}" != "default" ]; then
  themeValues=$(echo "${themes}" | jq -r ".${theme}")
  themePrimaryColour=$(echo "${themeValues}" | jq -r .primary)
  themeSecondaryColour=$(echo "${themeValues}" | jq -r .secondary)
  themeBorderColour=$(echo "${themeValues}" | jq -r .border)

  defaultThemeValues=$(echo "${themes}" | jq -r .default)
  defaultThemePrimaryColour=$(echo "${defaultThemeValues}" | jq -r .primary)
  defaultThemeSecondaryColour=$(echo "${defaultThemeValues}" | jq -r .secondary)
  defaultThemeBorderColour=$(echo "${defaultThemeValues}" | jq -r .border)
fi

rm -rf ./build ./dist
mkdir -p ./build/configs ./dist/cursors ./dist/cursors_scalable

cat >./dist/index.theme <<EOF
[Icon Theme]
Name=$(echo "${metadata}" | jq -r .name)
Comment=$(echo "${metadata}" | jq -r .comment)
Inherits=$(echo "${metadata}" | jq -r .inherits)
EOF

for scale in "${scales[@]}"; do
  scaledSize=$((size * scale))
  mkdir -p "./build/${scaledSize}x${scaledSize}"
done

applyThemeToSvg() {
  local svgData=$1

  if [ "${theme}" == "default" ]; then
    echo "${svgData}"
    return
  fi

  echo "${svgData}" | sed \
    -e "s/${defaultThemePrimaryColour}/${themePrimaryColour}/g" \
    -e "s/${defaultThemeSecondaryColour}/${themeSecondaryColour}/g" \
    -e "s/${defaultThemeBorderColour}/${themeBorderColour}/g"
}

mkLinuxCursor() {
  local name=$1
  local hotX=$2
  local hotY=$3
  local delays=$4
  local aliases=$5

  mkXCursor() {
    for scale in "${scales[@]}"; do
      local scaledSize=$((size * scale))
      local scaledHotX=$((hotX * scale))
      local scaledHotY=$((hotY * scale))

      local scaledDimensions="${scaledSize}x${scaledSize}"

      local buildDir="./build/${scaledDimensions}"
      local configFile="./build/configs/${name}.cursor"

      local magickArgs=(
        -scale "${scaledDimensions}"
      )

      if [ "${theme}" != "default" ]; then
        magickArgs+=(
          -fill "${themePrimaryColour}" -opaque "${defaultThemePrimaryColour}"
          -fill "${themeSecondaryColour}" -opaque "${defaultThemeSecondaryColour}"
          -fill "${themeBorderColour}" -opaque "${defaultThemeBorderColour}"
        )
      fi

      if [ "${delays}" == "null" ]; then
        local filename="${name}.png"

        magick "./assets/${filename}" "${magickArgs[@]}" "${buildDir}/${filename}"
        echo "${scaledSize} ${scaledHotX} ${scaledHotY} ${buildDir}/${filename}" >>"${configFile}"
      else
        local currentFrame=1

        echo "${delays}" | while read -r delay; do
          local filename="${name}-${currentFrame}.png"

          magick "./assets/${filename}" "${magickArgs[@]}" "${buildDir}/${filename}"
          echo "${scaledSize} ${scaledHotX} ${scaledHotY} ${buildDir}/${filename} ${delay}" >>"${configFile}"

          ((currentFrame++))
        done
      fi
    done

    xcursorgen "./build/configs/${name}.cursor" "./dist/cursors/${name}"
  }

  mkScalableCursor() {
    local distDir="./dist/cursors_scalable/${name}"
    local metadataFile="${distDir}/metadata.json"

    mkdir "${distDir}"

    echo "[" >>"${metadataFile}"

    if [ "${delays}" == "null" ]; then
      local infilename="${name}.png"
      local outfilename="${name}.svg"

      applyThemeToSvg "$(pixels2svg "./assets/${infilename}")" >"${distDir}/${outfilename}"
      echo "{ \"filename\": \"${outfilename}\", \"hotspot_x\": ${hotX}, \"hotspot_y\": ${hotY}, \"nominal_size\": ${size} }" >>"${metadataFile}"
    else
      local currentFrame=1

      echo "${delays}" | while read -r delay; do
        local infilename="${name}-${currentFrame}.png"
        local outfilename="${name}-${currentFrame}.svg"

        applyThemeToSvg "$(pixels2svg "./assets/${infilename}")" >"${distDir}/${outfilename}"
        echo "{ \"filename\": \"${outfilename}\", \"hotspot_x\": ${hotX}, \"hotspot_y\": ${hotY}, \"nominal_size\": ${size}, \"delay\": ${delay} }," >>"${metadataFile}"

        ((currentFrame++))
      done
    fi

    echo "]" >>"${metadataFile}"
  }

  mkXCursor
  mkScalableCursor

  if [ "${aliases}" != "null" ]; then
    echo "${aliases}" | while read -r alias; do
      ln -sr -T "./dist/cursors/${name}" "./dist/cursors/${alias}"
      ln -sr -T "./dist/cursors_scalable/${name}" "./dist/cursors_scalable/${alias}"
    done
  fi
}

echo "${cursors}" | jq -r 'keys[]' | while read -r name; do
  hotX=$(echo "${cursors}" | jq -r ".[\"${name}\"].hot_x")
  hotY=$(echo "${cursors}" | jq -r ".[\"${name}\"].hot_y")
  delays=$(echo "${cursors}" | jq -r ".[\"${name}\"].delays")
  aliases=$(echo "${cursors}" | jq -r ".[\"${name}\"].aliases")

  if [ "${delays}" != "null" ]; then
    delays=$(echo "${delays}" | jq -r ".[]")
  fi

  if [ "${aliases}" != "null" ]; then
    aliases=$(echo "${aliases}" | jq -r ".[]")
  fi

  echo "building '${name}' cursor..."
  mkLinuxCursor "${name}" "${hotX}" "${hotY}" "${delays}" "${aliases}"
done
