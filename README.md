[shmorgus]: https://shmorgus.itch.io/
[CC0]: https://creativecommons.org/public-domain/cc0/

<!---->

# Pixel Cursor Set

A full set of 8x8 pixel art cursors, built and distributed for Linux.

Around 1/2 of the assets used in this project were created by
[shmorgus][shmorgus] and published under [CC0][CC0], with the rest made by me.

## Dependencies

- [jq](https://github.com/jqlang/jq)
- [magick](https://github.com/ImageMagick/ImageMagick)
- [pixels2svg](https://github.com/ValentinFrancois/pixels2svg)
- [toml-cli](https://github.com/gnprice/toml-cli)
- [xcursorgen](https://wiki.archlinux.org/title/Xcursorgen)

> [!NOTE]
> The build script expects a `pixels2svg` binary, not the python library

## Building

After installing the necessary dependencies, run the following command:

```sh
$ sh ./scripts/build.sh
```

After building, you'll find two new folders in your working directory:

- `build`, containing resized versions of the original assets alonside some
  `.cursor` files for generating the X11 cursors.
- `dist`, containing the built cursors and an `index.theme` file for metadata.

For installation purposes, you can safely delete the `build` directory, leaving
only `dist`.

## Installation

For your system to find the cursors, you need to move them into
`~/.local/share/icons`. To do so, run the following commands in the same
directory you built the cursors:

```sh
# creating the target dir if it doesn't already exist
$ mkdir -p ~/.local/share/icons
# moving dist to the target dir, renaming in the process
$ mv ./dist ~/.local/share/icons/pixel-cursors
```

It'll now show up in your respective settings program. If you're on a distro
without an easy-to-use settings program, you probably skipped past this bit
anyway.

## License

This project is licensed under the terms of the GNU General Public License 3.0.
You can read the full license text in [LICENSE](./LICENSE).
