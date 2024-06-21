#!/bin/bash

[[ -n "${DEBUG}" ]] && set -x

L7_NVIM_CMD="de"

if which "${L7_NVIM_CMD}" 2>/dev/null; then
  echo "Conflicting command '${L7_NVIM_CMD}' already in PATH at $(which ${L7_NVIM_CMD})."
  echo "Choose a new name by rerunning with L7_NVIM_CMD=commandname or remove it"
  exit 1
fi

# Candidate directories for installation
bindirs=(
  "${HOME}/.local/share/bin" \
  "${HOME}/.local/bin" \
  "${HOME}/.bin" \
  "${HOME}/bin" \
  "${HOME}/scripts" \
  "${HOME}/opt/bin"
)

# see if any user installation dir already available
available_install_dirs() {
  for bindir in "${bindirs[@]}"; do
    echo $PATH | tr -d '[:space:]' | xargs -d: -I{} bash -c "[[ ${bindir} = {} ]] && [[ -d ${bindir} ]] && echo '${bindir}' || true"
  done
}

install_dir=$(available_install_dirs | head -n1)

mkdir -p "${install_dir}"

( [[ -z "${install_dir}" ]] || [[ ! -d "${install_dir}" ]] ) && cat <<EOT && exit 1
  Could not auto-detect appropriate installation directory. Put this in your shell profile and rerun:
  export PATH=\$HOME/.bin:\$PATH
EOT

entrypoint=$(realpath $(dirname "$0")/../devenv.sh)
if [[ ! -f "${entrypoint}" ]]; then
  echo "Missing file ${entrypoint} (resolved from $(realpath $(dirname "$0")/../devenv.sh))" >2&
  exit 1
fi

mkdir -p "${install_dir}"
dest="${install_dir}/${L7_NVIM_CMD}"

echo "Installing symlink ${entrypoint} -> ${dest}"
ln -s "${entrypoint}" "${dest}"

runshim="${dest}run"
echo "Installing shim ${runshim}"
cmd=$(which podman || which docker)
cat <<EOT > "${runshim}"
#!/bin/bash
entrypoint=\${1:-\$SHELL}
$cmd exec -it l7-nvim \$entrypoint "\${@:2}"
EOT
chmod +x "${runshim}"
