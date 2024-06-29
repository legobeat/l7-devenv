#!/bin/bash

########## FUNCTIONS

user_config () {
  ### dirs
  CONF_DIR="${CONF_DIR:-${HOME}/.config/l7ide/config}"
  LOCAL_DIR="${LOCAL_DIR:-${HOME}/.local/share/l7ide/local}"

  # .env is for current running environment; env gets loaded in container
  if [[ -f "${ROOT_DIR}/.env" ]]; then
    . "${ROOT_DIR}/.env"
  fi
  if [[ -f "${CONF_DIR}/.env" ]]; then
    . "${CONF_DIR}/.env"
  fi

  SRC_DIR="${SRC_DIR:-$(pwd)}"
  LOG_DIR="${LOG_DIR:-${HOME}/.local/share/l7ide/logs}"
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run/user/$(id -u)}"
  SSH_SOCKET="${SSH_SOCKET:-${SSH_AUTH_SOCK}}"

  ### mounts
  mkdir -p "${SRC_DIR}"
  mkdir -p "${LOG_DIR}"
  mkdir -p "${CONF_DIR}/ssh.d" "${LOCAL_DIR}/ssh" "${CONF_DIR}/git"
  touch "${CONF_DIR}/git/config"
  mkdir -p ~/.local/share/l7ide/node-runner/{yarn/cache/classic,yarn/cache/berry,npm/cache,node/cache}
  mkdir -p ~/.local/share/l7ide/gh && touch ~/.local/share/l7ide/gh/hosts.yml && chmod 0600 ~/.local/share/l7ide/gh/hosts.yml
  mkdir -p ~/.local/share/l7ide/go-runner/go
  mkdir -p ~/.local/share/l7ide/apt-cacher-ng/cache
}

runtime_config () {
  cmd="${CONTAINER_CMD:-$(detect_runtime_command)}"
  if [[ -z "${cmd}" ]]; then
    echo "Missing container rumtime. Install podman or set env var CONTAINER_CMD." >&2
    exit 1
  fi
  composecmd="${COMPOSE_CMD:-$(detect_compose_command)}"
  NAME="${NAME:-l7-nvim}"
  IMAGE_TAG=${IMAGE_TAG:-latest}
  IMAGE_NAME=${IMAGE_NAME:-localhost/l7/nvim}
  IMAGE=${IMAGE:-$IMAGE_NAME:$IMAGE_TAG}

  GO_RUNNER_IMAGE="${GO_RUNNER_IMAGE:-localhost/l7/go:1.20-bookworm}"
  NODE_RUNNER_IMAGE="${NODE_RUNNER_IMAGE:-localhost/l7/node:20-bookworm}"
  GPG_IMAGE="${GPG_IMAGE:-localhost/l7/gpg-vault:pk}"

  CONTAINER_DNS="${CONTAINER_DNS:-10.7.8.133}"

  # compose, used for sidecars and leaked into de
  CONTAINER_SOCKET="${CONTAINER_SOCKET:-${XDG_RUNTIME_DIR}/podman/podman.sock}"
  # CONTAINER_SOCKET is leaked into the container and used by de container to run sidecars
  if [[ -z "${CONTAINER_SOCKET}" || ! -f "${CONTAINER_SOCKET}" ]]; then
    CONTAINER_SOCKET="${CONTAINER_SOCKET:-/var/run/docker.sock}"
  fi

  # used to run de itself. could (should) be separate from CONTAINER_SOCKET
  export DOCKER_HOST="${DOCKER_HOST:-unix://${CONTAINER_SOCKET}}"

  if [[ -z "${NETWORK_NAME}" ]]; then
    COMPOSE_NETWORK_NAME="${COMPOSE_NETWORK_NAME:-internal}"
    NETWORK_NAME=${NETWORK_NAME:-$(get_compose_network_name "${COMPOSE_NETWORK_NAME}")}
  fi

  ### run args
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
  RESOLV_CONF_PATH="${L7_RESOLV_CONF_PATH:-$(mktemp)}"
  echo "nameserver ${CONTAINER_DNS}" > "${RESOLV_CONF_PATH}"

  # detect tty
  if [ -t 1 ] ; then
    RUN_ARGS="${RUN_ARGS} -t "
  fi
}

detect_runtime_command() {
  # note: docker is not tested, let me know if you insist and get it working or not
  cmd="${CONTAINER_CMD:-$(which podman || which docker)}"
  echo "${cmd}"
}

detect_compose_command() {
  if [[ "$(basename "${cmd}")" == "podman" ]]; then
    # could do backwards compat here by falling back to podman-compose
    composecmd="${cmd} compose"
    if [[ -z "${FORCE_PODMAN_VERSION}" ]]; then
      podman_version=$(${cmd} version -f json | jq -r .Client.APIVersion)
      if [[ ! "${podman_version}" = [45]* ]]; then
        echo "Incompatible Podman API version ${podman_version}, needs 4.x"
      fi
    fi
  else
    composecmd="$(which docker-compose)"
  fi
  if [[ -z "${composecmd}" ]]; then
    echo "Could not detect compose command. Install a newer version of ${cmd}-compose or set it by COMPOSE_CMD" >&2
    exit 1
  fi
  echo "${composecmd}"
}

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

configure_gh_token() {
  mkdir -p "${CONF_DIR}/git-auth-proxy"
  local cfg="${CONF_DIR}/git-auth-proxy/config.json"
  local cfg_tmpl="${cfg}.tmpl"
  if [[ ! -f "${cfg}" ]]; then
     msg="${msg}No auth-proxy configuration found at ${cfg}. "
    if [[ ! -f "${cfg_tmpl}" ]]; then
      tmpl_src="${ROOT_DIR}/examples/auth-proxy.default.json.tmpl"
      msg="${msg}Copying default template from ${tmpl_src} to ${cfg_tmpl}. " >&2
      cp "${tmpl_src}" "${cfg_tmpl}"
    fi
  fi
  if [[ -f "${cfg_tmpl}" ]]; then
    # allow supplying secrets via stdout of command to avoid leaking
    if [[ -n "${L7_GITHUB_TOKEN_CMD}" ]] ; then
      local L7_GITHUB_TOKEN="$(L7_GITHUB_TOKEN_CMD)"
      # TODO: diff with old value, only restart if different
      SHOULD_RESTART_HTTP_PROXY=1
    fi
    if [[ -z "${L7_USER_TOKEN_HASH}" ]]; then
      L7_USER_TOKEN="$(head -c 1000 /dev/random | base32 | head -c32)"
      msg="${msg}Generated new internal gh auth token. " >&2
      L7_USER_TOKEN_HASH="$(mkpasswd -m sha512crypt "${L7_USER_TOKEN}")"
      SHOULD_RESTART_HTTP_PROXY=1
    fi
    [[ -n "${msg}" ]] && echo "${msg}"
    # todo: use podman secrets or sth instead of passing around env vars and files
    # simple templating
    envsubst '${L7_GITHUB_TOKEN},${L7_USER_TOKEN_HASH}' < "${cfg_tmpl}" > "${cfg}"

    if [[ -n "${SHOULD_RESTART_HTTP_PROXY}" ]]; then
      # restart auth-proxy if already running
      auth_proxy_name=$(get_compose_container_name 'auth-proxy')
      "${cmd}" restart --running "${auth_proxy_name}" >/dev/null 2>/dev/null || true
    fi

    # if existing user-auth token is provided and not set in user env conf, remove any existing one and replace
    if [[ -n "${L7_USER_TOKEN}" ]]; then
      envcfg="${CONF_DIR}/env"
      if [[ -f "${envcfg}" ]]; then
        grep --quiet "^GITHUB_TOKEN=${L7_USER_TOKEN}$" "${envcfg}"
        if (( $? != 0 )); then
          cp -b "${envcfg}" "${envcfg}.backup"
          grep -Ev '^GITHUB_TOKEN=|^GH_TOKEN=' "${envcfg}" \
            | sponge "${envcfg}"
        fi
      fi
      echo "GITHUB_TOKEN=${L7_USER_TOKEN}" >> "${envcfg}"
    fi
    # if existing gh token is provided and not set in env conf, remove any existing one and replace
    if [[ -n "${L7_GITHUB_TOKEN}" ]]; then
      envcfg="${CONF_DIR}/.env"
      if [[ -f "${envcfg}" ]]; then
        grep --quiet "^L7_GITHUB_TOKEN=${L7_GITHUB_TOKEN}$" "${envcfg}"
        if (( $? != 0 )); then
          cp -b "${envcfg}" "${envcfg}.backup"
          grep -Ev '^L7_GITHUB_TOKEN=|GITHUB_TOKEN=|^GH_TOKEN=' "${envcfg}" \
            | sponge "${envcfg}"
        fi
      fi
      echo "L7_GITHUB_TOKEN=${L7_GITHUB_TOKEN}" >> "${envcfg}"
      echo "L7_USER_TOKEN_HASH=${L7_USER_TOKEN_HASH}" >> "${envcfg}"
    fi
  fi
}

start_compose () {
  (cd "${ROOT_DIR}" \
    && DOCKER_HOST="unix://${CONTAINER_SOCKET}" \
      ${composecmd} up -d >> "${LOG_DIR}/compose.log" 2>> "${LOG_DIR}/compose.err"
  )
}

########## MAIN

if [[ -n "${DEBUG}" ]]; then
  set -x
fi

# default workdir to pwd if within SRC_DIR or /src; otherwise SRC_DIR
if [ -z "${CWD}" ]; then
  case $PWD/ in
    ${SRC_DIR}/*) export CWD="${PWD}";;
    /src/*)       export CWD="${PWD}";;
    *)            export CWD="${SRC_DIR}";;
  esac
fi

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script/1482133#1482133
ROOT_DIR="${ROOT_DIR:-$(dirname -- "$( readlink -f -- "$0"; )")}"

if [[ -n "${1}" ]]; then
  RUN_ARGS="${RUN_ARGS} --entrypoint ${1}"
fi

user_config
runtime_config
configure_gh_token
start_compose

${cmd} network ls --filter="name=${NETWORK_NAME}" | grep --quiet "${NETWORK_NAME}" >/dev/null 2>/dev/null
if (( $? != 0 )) ; then
  echo "Could not find expected ${CMD} network '${NETWORK_NAME}'. Run '$(basename "${composecmd}") up' in a separate terminal or supply the network name via the NETWORK_NAME env var." >&2
  exit 1
fi

${cmd} run --rm -i \
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
  -e "L7_COMPOSE_NETWORK_NAME_INTERNAL=${NETWORK_NAME}" \
  -e "L7_RESOLV_CONF_PATH=${RESOLV_CONF_PATH}" \
  -e "CONTAINER_HOST=unix:///run/docker.sock" \
  -e "GO_RUNNER_IMAGE=${GO_RUNNER_IMAGE}" \
  -e "NODE_RUNNER_IMAGE=${NODE_RUNNER_IMAGE}" \
  -e "GPG_IMAGE=${GPG_IMAGE}" \
  -e HOME=/home/user \
  -e "SRC_DIR=${SRC_DIR}" \
  --network "${NETWORK_NAME}" \
  --dns "${CONTAINER_DNS}" \
  ${RUN_ARGS} \
  "${IMAGE}" \
  ${@:2}

###
# --sysctl "net.ipv4.ping_group_range=1000 1000" \
