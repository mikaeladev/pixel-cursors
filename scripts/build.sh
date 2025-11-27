#!/usr/bin/env bash

config=$(toml get ./config.toml .)
theme=$(echo "${config}" | jq -r .theme)
cursors=$(echo "${config}" | jq -r .cursors)

size=12
scales=(1 2 3 4 5 6)

rm -rf ./build ./dist
mkdir -p ./build/configs ./dist/cursors ./dist/cursors_scalable

cat >./dist/index.theme <<EOF
[Icon Theme]
Name=$(echo "${theme}" | jq -r ".name")
Comment=$(echo "${theme}" | jq -r ".comment")
Inherits=$(echo "${theme}" | jq -r ".inherits")
EOF

for scale in "${scales[@]}"; do
  scaledSize=$((size * scale))
  mkdir -p "./build/${scaledSize}x${scaledSize}"
done

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

      if [ "${delays}" == "null" ]; then
        local filename="${name}.png"

        magick "./assets/${filename}" -scale "${scaledDimensions}" "${buildDir}/${filename}"
        echo "${scaledSize} ${scaledHotX} ${scaledHotY} ${buildDir}/${filename}" >>"${configFile}"
      else
        local currentFrame=1

        echo "${delays}" | while read -r delay; do
          local filename="${name}-${currentFrame}.png"

          magick "./assets/${filename}" -scale "${scaledDimensions}" "${buildDir}/${filename}"
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

      pixels2svg -o "${distDir}/${outfilename}" "./assets/${infilename}"
      echo "{ \"filename\": \"${outfilename}\", \"hotspot_x\": ${hotX}, \"hotspot_y\": ${hotY}, \"nominal_size\": ${size} }" >>"${metadataFile}"
    else
      local currentFrame=1

      echo "${delays}" | while read -r delay; do
        local infilename="${name}-${currentFrame}.png"
        local outfilename="${name}-${currentFrame}.svg"

        pixels2svg -o "${distDir}/${outfilename}" "./assets/${infilename}"
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

  echo "building '${name}' cursor"
  mkLinuxCursor "${name}" "${hotX}" "${hotY}" "${delays}" "${aliases}" &
done
