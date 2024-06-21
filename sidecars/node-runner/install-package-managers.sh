#!/bin/sh

# install package managers in parallel

echo "${COREPACK_PMS}" | \
  xargs -P8 -n1 corepack install -g
