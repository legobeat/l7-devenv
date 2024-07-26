#!/bin/sh
# generate tiling background wallpaper
# https://www.imagemagick.org/Usage/backgrounds/
img_noise="$(mktemp)-noise.png"
img_bg="$(mktemp)-bg.png"
tile_size=200x200

magick -size "${tile_size}" xc: +noise Random "${img_noise}"

magick "${img_noise}" \
  -virtual-pixel tile -blur 0x5 -normalize \
  -fx g -sigmoidal-contrast 15x50% -solarize 50% \
  "${img_bg}"

feh --bg-tile "${img_bg}"

