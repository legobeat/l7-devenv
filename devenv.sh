#!/bin/bash

CONF_DIR="${CONF_DIR:-${HOME}/.config/l7ide/config}"
LOCAL_DIR="${LOCAL_DIR:-${HOME}/.local/share/l7ide/local}"
SRC_DIR="${SRC_DIR:-$(pwd)}"
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script/1482133#1482133
ROOT_DIR="${ROOT_DIR:-$(dirname -- "$( readlink -f -- "$0"; )")}"

# .env is for current running environment; env gets loaded in container
if [[ -f "${ROOT_DIR}/.env" ]]; then
  . "${ROOT_DIR}/.env"
fi
if [[ -f "${CONF_DIR}/.env" ]]; then
  . "${CONF_DIR}/.env"
fi


if [[ -n "${DEBUG}" ]]; then
  set -x
fi

get_compose_name() {
  basename "${ROOT_DIR}"
}

get_compose_network_name() {
  name="$1"
  cn="$(get_compose_name)"
  echo -n "${cn}_${name}"
}

get_compose_container_name() {
  name="$1"
  cn="$(get_compose_name)"
  echo -n "${cn}-${name}-1"
}

IMAGE_TAG=${IMAGE_TAG:-latest}
IMAGE_NAME=${IMAGE_NAME:-localhost/l7/nvim}
IMAGE=${IMAGE:-$IMAGE_NAME:$IMAGE_TAG}
NAME="${NAME:-l7-nvim}"

# default workdir to pwd if within SRC_DIR or /src; otherwise SRC_DIR
if [ -z "${CWD}" ]; then
  case $PWD/ in
    ${SRC_DIR}/*) export CWD="${PWD}";;
    /src/*)       export CWD="${PWD}";;
    *)            export CWD="${SRC_DIR}";;
  esac
fi

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

mkdir -p "${CONF_DIR}/ssh.d" "${LOCAL_DIR}/ssh" "${CONF_DIR}/git"
touch "${CONF_DIR}/git/config"
# for node modules cache mounts
mkdir -p "${HOME}"/.local/share/l7ide/node-runner/{yarn/cache/classic,yarn/cache/berry,npm/cache,node/cache}
mkdir -p ~/.local/share/l7ide/gh && touch ~/.local/share/l7ide/gh/hosts.yml && chmod 0600 ~/.local/share/l7ide/gh/hosts.yml
mkdir -p ~/.local/share/l7ide/go-runner/go

configure_gh_token() {
  mkdir -p "${HOME}/.config/l7ide/config/git-auth-proxy"
  local cfg="${HOME}/.config/l7ide/config/git-auth-proxy/config.json"
  if [[ ! -f "${cfg}" ]]; then
    cp sidecars/git-auth-proxy/examples/default.json "${cfg}"
  fi
  # simple templating
  # todo: use podman secrets or sth
  if [[ -f "${cfg}.tmpl" ]]; then
    # allow supplying secret via stdout of command to avoid leaking
    if [[ -n "${L7_GITHUB_TOKEN_CMD}" ]] ; then
      local L7_GITHUB_TOKEN=$(L7_GITHUB_TOKEN_CMD)
    fi
    envsubst L7_GITHUB_TOKEN < "${cfg}.tmpl" > "${cfg}"
  fi
}

configure_gh_token

# note: docker is not tested, let me know if you insist and get it working
cmd="${CONTAINER_CMD:-$(which podman || which docker)}"
if [[ "$(basename "${cmd}")" == "podman" ]]; then
  # could do backwards compat here by falling back to podman-compose
  composecmd="${cmd} compose"
  # compose, used for sidecars and leaked into de
  CONTAINER_SOCKET="${CONTAINER_SOCKET:-${XDG_RUNTIME_DIR}/podman/podman.sock}"
  # used to run de itself. could be separate
  export DOCKER_HOST="${DOCKER_HOST:-unix://${XDG_RUNTIME_DIR}/podman/podman.sock}"
  if [[ -z FORCE_PODMAN_VERSION ]]; then
    podman_version=$(${cmd} version -f json | jq -r .Client.APIVersion)
    if [[ ! "${podman_version}" = [45]* ]]; then
      echo "Incompatible Podman API version ${podman_version}, needs 4.x"
    fi
  fi
else
  composecmd='docker-compose'
fi

LOG_DIR="${LOG_DIR:-${HOME}/.local/share/l7ide/logs}"
mkdir -p "${LOG_DIR}"
(cd "${ROOTDIR}" \
	&& DOCKER_HOST="unix://${CONTAINER_SOCKET}" \
	  ${composecmd} up -d >> "${LOG_DIR}/compose.log" 2>> "${LOG_DIR}/compose.err"
)

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

if [[ -f "${ROOT_DIR}/env" ]]; then
  RUN_ARGS="${RUN_ARGS} --env-file ${ROOT_DIR}/env"
fi
if [[ -f "${CONF_DIR}/env" ]]; then
  RUN_ARGS="${RUN_ARGS} --env-file ${CONF_DIR}/env"
fi

if [[ "$(id -u)" -ne "0"  && ! "${cmd}" == sudo\ * ]]; then
  # uidmap for rootless
  uid=$(id -u)
  gid=$(id -g)
  RUN_ARGS="${RUN_ARGS} \
    --user ${uid}:${gid} --userns=keep-id:uid=${uid},gid=${gid} \
  "
  # below uidmap/gidmap monstrosity is compat alternative on podman <4.3
  ## https://github.com/containers/podman/blob/main/troubleshooting.md#39-podman-run-fails-with-error-unrecognized-namespace-mode-keep-iduid1000gid1000-passed
  #subuidSize=$(( $(${cmd} info --format "{{ range \
  #   .Host.IDMappings.UIDMap }}+{{.Size }}{{end }}" ) - 1 ))
  #subgidSize=$(( $(${cmd} info --format "{{ range \
  #   .Host.IDMappings.GIDMap }}+{{.Size }}{{end }}" ) - 1 ))
  #RUN_ARGS="${RUN_ARGS}
  #  --uidmap 0:1:$uid
  #  --uidmap $uid:0:1
  #  --uidmap $(($uid+1)):$(($uid+1)):$(($subuidSize-$uid))
  #  --gidmap 0:1:$gid
  #  --gidmap $gid:0:1
  #  --gidmap $(($gid+1)):$(($gid+1)):$(($subgidSize-$gid))
  #"
fi

# podman / netavark hijack both dns and/or resolv.conf no matter what, it seems...
RESOLV_CONF_PATH=$(mktemp)
echo "nameserver 10.7.8.133" > "${RESOLV_CONF_PATH}"

${cmd} run --rm -it \
  --user "$(id -u):$(id -g)" \
  --mount type=bind,source="${LOCAL_DIR},target=/home/user/.local" \
  --mount type=bind,source="${CONF_DIR}/ssh.d,target=/home/user/.ssh/config.d,ro=true" \
  --mount type=bind,source="${CONF_DIR}/git,target=/home/user/.config/git,ro=true" \
  -v "${CONTAINER_SOCKET}:/run/docker.sock" \
  -v "${SRC_DIR}:${SRC_DIR}:Z" \
  -v "${SRC_DIR}:/src:Z" \
  -v "${RESOLV_CONF_PATH}:/etc/resolv.conf:ro" \
  -w "${CWD}" \
  --mount type=tmpfs,tmpfs-size=2G,destination=/tmp,tmpfs-mode=0777 \
  -e "L7_COMPOSE_NETWORK_NAME_INTERNAL=$(get_compose_network_name 'internal')" \
  -e "L7_RESOLV_CONF_PATH=${RESOLV_CONF_PATH}" \
  -e "CONTAINER_HOST=unix:///run/docker.sock" \
  -e GO_RUNNER_IMAGE=localhost/l7/go:1.20-bookworm \
  -e NODE_RUNNER_IMAGE=localhost/l7/node:20-bookworm \
  -e GPG_IMAGE=localhost/l7/gpg-vault:pk \
  -e HOME=/home/user \
  -e "SRC_DIR=${SRC_DIR}" \
  --network "$(get_compose_network_name 'internal')" \
  --dns '10.7.8.133' \
  ${RUN_ARGS} \
  "${IMAGE}" \
  ${@:2}

###
# --sysctl "net.ipv4.ping_group_range=1000 1000" \
