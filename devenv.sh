#!/bin/bash

if [[ -n "${DEBUG}" ]]; then
  set -x
fi

IMAGE_TAG=${IMAGE_TAG:-latest}
IMAGE_NAME=${IMAGE_NAME:-localhost/l7/nvim}
IMAGE=${IMAGE:-$IMAGE_NAME:$IMAGE_TAG}

CONF_DIR="${CONF_DIR:-${HOME}/.config/l7ide/config}"
LOCAL_DIR="${LOCAL_DIR:-${HOME}/.local/share/l7ide/local}"
SRC_DIR="${SRC_DIR:-$(pwd)}"
# default workdir to pwd if within SRC_DIR or /src; otherwise SRC_DIR
if [ -z "${CWD}" ]; then
  case $PWD/ in
    ${SRC_DIR}/*) export CWD="${PWD}";;
    /src/*)       export CWD="${PWD}";;
    *)            export CWD="${SRC_DIR}";;
  esac
fi
CONTAINER_SOCKET="${XDG_RUNTIME_DIR}/podman/podman.sock"

mkdir -p "${CONF_DIR}/ssh.d" "${LOCAL_DIR}/ssh"
touch "${CONF_DIR}/gitconfig"
# for node modules cache mounts
mkdir -p ${HOME}/.local/share/l7ide/node-runner/{yarn/cache/classic,yarn/cache/berry,npm/cache,node/cache}
mkdir -p ~/.local/share/l7ide/gh && touch ~/.local/share/l7ide/gh/hosts.yml && chmod 0600 ~/.local/share/l7ide/gh/hosts.yml


# note: docker is not tested, let me know if you insist and get it working
cmd=$(which podman || which docker)

SSH_SOCKET="${SSH_SOCKET:-${SSH_AUTH_SOCK}}"
if [[ -n "${SSH_SOCKET}" ]]; then
  RUN_ARGS="${RUN_ARGS} -v ${SSH_SOCKET}:${HOME}/.ssh/SSH_AUTH_SOCK -e SSH_AUTH_SOCK=${HOME}/.ssh/SSH_AUTH_SOCK"
fi
if [[ -n "${NAME}" ]]; then
  RUN_ARGS="${RUN_ARGS} --name ${NAME} --hostname ${NAME}"
fi

GPG_PK_VOLUME=${GPG_PK_VOLUME:-"l7-gpg-vault-pk"}
if [[ -n "${GPG_PK_VOLUME}" ]]; then
  RUN_ARGS="${RUN_ARGS} -e GPG_PK_VOLUME=${GPG_PK_VOLUME}"
fi

if [[ -n "${1}" ]]; then
  RUN_ARGS="${RUN_ARGS} --entrypoint ${1}"
fi

# uid mapping wip, sudo not working yet
# https://github.com/containers/podman/discussions/22444
  #--user "$(id -u):$(id -g)" --uidmap "$(id -u):0:1" --uidmap '0:1:1' --sysctl "net.ipv4.ping_group_range=1000 1000" \
  # --sysctl "net.ipv4.ping_group_range=1000 1000" \
${cmd} run --rm -it \
  --user "$(id -u):$(id -g)" --userns=keep-id:uid=$(id -u),gid=$(id -g) \
  --mount type=bind,source="${LOCAL_DIR},target=/home/user/.local" \
  --mount type=bind,source="${CONF_DIR}/ssh.d,target=/home/user/.ssh/config.d,ro=true" \
  --mount type=bind,source="${CONF_DIR}/gitconfig,target=/home/user/.config/gitconfig,ro=true" \
  -v "${CONTAINER_SOCKET}:/run/docker.sock" \
  -v "${SRC_DIR}:${SRC_DIR}:Z" \
  -v "${SRC_DIR}:/src:Z" \
  -w "${CWD}" \
  --mount type=tmpfs,tmpfs-size=2G,destination=/tmp,U=true,tmpfs-mode=0777 \
  -e "CONTAINER_HOST=unix:///run/docker.sock" \
  -e NODE_RUNNER_IMAGE=localhost/l7/node:20-bookworm \
  -e GPG_IMAGE=localhost/l7/gpg-vault:pk \
  -e HOME=/home/user \
  -e "SRC_DIR=${SRC_DIR}" \
  ${RUN_ARGS} \
  "${IMAGE}" \
  ${@:2}
