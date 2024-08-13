#!/bin/bash
find ${HOME}/.config/xresources/ \
  -maxdepth 3 -name '*.Xresources' \
  -exec xrdb -m '{}'  \;
