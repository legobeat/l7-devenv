#!/bin/sh

# install package managers in parallel

shim_pm_versions () {
  mkdir -p "${HOME}/.corepack/bin"
  for pmv in ${COREPACK_PMS}; do
    pm_name="$(echo $pmv | grep -o '^[^@]*')"
    pm_version="$(echo $pmv | grep -o '[^@]*$')"
    pm_major_version="$(echo $pm_version | grep -o '^[0-9]*')"
    pm_manifest="$(find "${HOME}/.cache/node/corepack/" -maxdepth 4 -type f -path "*/${pm_name}/${pm_version}*" -name .corepack | head -n1)"

    pm_bin=$(realpath "$(dirname "${pm_manifest}")/$(jq -r ".bin.${pm_name}" "${pm_manifest}")") 2>/dev/null
    if [ ! -f ${pm_bin} ]; then
      pm_bin=$(realpath "$(dirname "${pm_manifest}")/${pm_name}.js")
    fi

    # insert shebang if missing
    sed -i -z 's@^[^#]@#!/usr/bin/env node\n\0@' "${pm_bin}"
    chmod +x "${pm_bin}"
    ln -s "${pm_bin}" "${HOME}/.corepack/bin/${pm_name}${pm_version}"
    ln -sf "${pm_bin}" "${HOME}/.corepack/bin/${pm_name}${pm_major_version}"
  done
}

echo "${COREPACK_PMS}" | \
  xargs -P8 -n1 corepack install -g

shim_pm_versions
