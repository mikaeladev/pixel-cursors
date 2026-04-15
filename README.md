# Pixel Cursors

A set of 8x8 pixel-art cursors for Linux.

<!-- insert image showing off the cursors here -->

## Building

Before you continue, make sure the necessary dependencies are installed:

- [jq] (json query/manipulation)
- [magick] (image manipulation)
- [pixel-to-svg] (raster to vector conversion)
- [toml-cli] (toml to json conversion)
- [xcursorgen] (xcursor generation)

Afterwards, run the build script like so:

```sh
sh scripts/build.sh # [THEME]
```

The build script takes the following environment variables:

| Name              | Description                         | Default Value |
| ----------------- | ----------------------------------- | ------------- |
| `DEBUG`           | Whether to enable debug logs        | `false`       |
| `QUIET`           | Whether to suppress all logs        | `false`       |
| `THEME`           | Name of the theme to apply          | `default`     |
| `ASSET_SIZE`      | Expected width/height of assets     | `12`          |
| `ASSET_MAX_SCALE` | Maximum xcursor image scale         | `6`           |
| `ASSET_PATH`      | Location of the assets directory    | `assets`      |
| `BUILD_PATH`      | Location of the build directory     | `build`       |
| `BUILD_KEEP`      | Whether to keep the build directory | `$DEBUG`      |
| `DIST_PATH`       | Location of the dist directory      | `dist`        |

Note that environment variables take priority over arguments (e.g. `$THEME` is
greater than `$1`)

## Acknowledgements

This project was directly inspired by the work of [shmorgus] and their
[Universal Icon Pack], with some of the assets being taken directly from there.
If you like their art style and have the money to spare, I highly encourage you
to go support their work on [itch.io][shmorgus] (name your own price).

## License

This project is licensed under the terms of the GNU General Public License 3.0.
You can read the full license text in [LICENSE](./LICENSE).

[jq]: https://github.com/jqlang/jq
[magick]: https://github.com/ImageMagick/ImageMagick
[pixel-to-svg]: https://github.com/mikaeladev/pixel-to-svg
[shmorgus]: https://shmorgus.itch.io/
[toml-cli]: https://github.com/gnprice/toml-cli
[universal icon pack]: https://shmorgus.itch.io/micro-icon-pack
[xcursorgen]: https://wiki.archlinux.org/title/Xcursorgen
