#!/bin/sh

autossh \
  -M 0\
  -oExitOnForwardFailure=yes \
  "${@}" \
   | grep -o '^[a-z0-9]*://[^\s]*\.link$' \
   | sed -e 's#^[a-z0-9]*#\n  *** VNC VIEWER EXPOSED ***\nYou can now share access by sharing:\nhttps#' \
    -e 's#$#/vnc.html\n#'



#   | grep -o '^[a-z0-9]*://[^\s]*' | sed -e 's#^[a-z0-9]*#\n  You can now share a remote view or control (depending on server authentication) via sharing:\nhttps#' -e 's#$#/vnc.html\n#'
# TODO: something with ssh tty to make capturing output work
