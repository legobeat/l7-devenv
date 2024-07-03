#!/bin/bash

########## FUNCTIONS

user_config () {
  ### dirs
  CONF_DIR="${CONF_DIR:-${HOME}/.config/l7ide/config}"
  LOCAL_DIR="${LOCAL_DIR:-${HOME}/.local/share/l7ide/local}"
  NODE_CACHE_DIR="${NODE_CACHE_DIR:-$(mktemp -d -t l7-node-cache.XXXX --tmpdir)}"
  chmod 777 "${NODE_CACHE_DIR}"

  # .env is for current running environment; env gets loaded in container
  if [[ -f "${ROOT_DIR}/.env" ]]; then
    . "${ROOT_DIR}/.env"
  fi
  if [[ -f "${CONF_DIR}/.env" ]]; then
    . "${CONF_DIR}/.env"
  fi

  SRC_DIR="${SRC_DIR:-${L7_SRC_DIR:-$(pwd)}}"
  LOG_DIR="${LOG_DIR:-${HOME}/.local/share/l7ide/logs}"
  XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/var/run/user/$(id -u)}"
  SSH_SOCKET="${SSH_SOCKET:-${SSH_AUTH_SOCK}}"

  ### mounts
  mkdir -p "${SRC_DIR}"
  mkdir -p "${LOG_DIR}"
  mkdir -p "${CONF_DIR}/ssh.d" "${LOCAL_DIR}/ssh" "${CONF_DIR}/git"
  touch "${CONF_DIR}/git/config"
  mkdir -p ${NODE_CACHE_DIR}/{yarn/cache/classic,yarn/cache/berry,npm/cache,node/cache,pnpm/cache}
  mkdir -p ~/.local/share/l7ide/gh && touch ~/.local/share/l7ide/gh/hosts.yml && chmod 0600 ~/.local/share/l7ide/gh/hosts.yml
  mkdir -p ~/.local/share/l7ide/go-runner/go
  mkdir -p ~/.local/share/l7ide/nvim/state
  mkdir -p ~/.local/share/l7ide/apt-cacher-ng/cache
}

runtime_config () {
  if [[ "$(id -u)" -eq "0"  || "${cmd}" == sudo\ * ]]; then
    if [[ -z "${L7_FORCE_UNSAFE_ROOT}" ]]; then
      echo "ERROR: Running as superuser is unsupported. Do not run as root."
      exit 1
    fi
  fi

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
  export CONTAINER_SOCKET

  # used to run de itself. should be separate from CONTAINER_HOST inside de itself
  export DOCKER_HOST="${DOCKER_HOST:-unix://${CONTAINER_SOCKET}}"

  if [[ -z "${NETWORK_NAME}" ]]; then
    COMPOSE_NETWORK_NAME="${COMPOSE_NETWORK_NAME:-internal}"
    NETWORK_NAME=${NETWORK_NAME:-$(get_compose_network_name "${COMPOSE_NETWORK_NAME}")}
  fi
  if [[ -z "${CONTROL_NETWORK_NAME}" ]]; then
    CONTROL_COMPOSE_NETWORK_NAME="${CONTROL_COMPOSE_NETWORK_NAME:-container-control}"
    CONTROL_NETWORK_NAME=${CONTROL_NETWORK_NAME:-$(get_compose_network_name "${CONTROL_COMPOSE_NETWORK_NAME}")}
  fi

  ### run args
  if [[ -n "${SSH_SOCKET}" ]]; then
    RUN_ARGS="${RUN_ARGS} -v ${SSH_SOCKET}:${HOME}/.ssh/SSH_AUTH_SOCK:Z -e SSH_AUTH_SOCK=${HOME}/.ssh/SSH_AUTH_SOCK"
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
  if [[ "${L7_DISABLE_SELINUX}" == "1" ]]; then
    RUN_ARGS="${RUN_ARGS} --security-opt=label=disable"
  fi

  # podman / netavark hijack both dns and/or resolv.conf no matter what, it seems...
  RESOLV_CONF_PATH="${L7_RESOLV_CONF_PATH:-$(mktemp -t l7-resolvconf.XXX --tmpdir)}"
  echo "nameserver ${CONTAINER_DNS}" > "${RESOLV_CONF_PATH}"
  NVIM_STATE_PATH="${L7_NVIM_STATE_PATH:-$(mktemp -d -t l7-nvim-state.XXXX --tmpdir)}"

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

# set value in shell env file
envfile_upsert_shell() {
  envcfg="${1}"
  name="${2}"
  value="${3}"
  # remove old value, if any, and replace
  if [[ -f "${envcfg}" ]]; then
    grep --quiet "^${name}=${val}$" "${envcfg}"
    if (( $? == 0 )); then
      # new value already set
      return
    fi
    grep -Ev "^(export\s)?\s*${name}=" "${envcfg}" > "${envcfg}.new"
  fi
  echo "export ${name}='${value}'" >> "${envcfg}.new"
  mv -b "${envcfg}.new" "${envcfg}"
}

# set value in podman .env file
envfile_upsert() {
  envcfg="${1}"
  name="${2}"
  value="${3}"
  # remove old value, if any, and replace
  if [[ -f "${envcfg}" ]]; then
    grep --quiet "^${name}=${val}$" "${envcfg}"
    if (( $? == 0 )); then
      # new value already set
      return
    fi
    grep -Ev "^${name}=" "${envcfg}" > "${envcfg}.new"
  fi
  echo "${name}=${value}" >> "${envcfg}.new"
  mv -b "${envcfg}.new" "${envcfg}"
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
      export L7_GITHUB_TOKEN="$(L7_GITHUB_TOKEN_CMD)"
      # TODO: diff with old value, only restart if different
      SHOULD_RESTART_HTTP_PROXY=1
    fi
    if [[ -z "${L7_USER_TOKEN_HASH}" ]]; then
      export L7_USER_TOKEN="$(head -c 1000 /dev/random | base32 | head -c32)"
      msg="${msg}Generated new internal gh auth token. " >&2
      export L7_USER_TOKEN_HASH="$(mkpasswd -m sha512crypt "${L7_USER_TOKEN}")"
      SHOULD_RESTART_HTTP_PROXY=1
    fi
    [[ -n "${msg}" ]] && echo "${msg}" >&2
    # todo: use podman secrets or sth instead of passing around env vars and files
    # simple templating
    L7_GITHUB_TOKEN="${L7_GITHUB_TOKEN}" L7_USER_TOKEN_HASH="${L7_USER_TOKEN_HASH}" \
      envsubst '${L7_GITHUB_TOKEN},${L7_USER_TOKEN_HASH}' < "${cfg_tmpl}" > "${cfg}"

    # if existing user-auth token is provided and not set in user env conf, remove any existing one and replace
    if [[ -n "${L7_USER_TOKEN}" ]]; then
      envfile_upsert "${CONF_DIR}/env" GITHUB_TOKEN "${L7_USER_TOKEN}"
      envfile_upsert "${CONF_DIR}/env" GH_TOKEN     "${L7_USER_TOKEN}"
    fi
    # if existing gh token is provided and not set in env conf, remove any existing one and replace
    if [[ -n "${L7_GITHUB_TOKEN}" ]]; then
      envfile_upsert_shell "${CONF_DIR}/.env" L7_GITHUB_TOKEN "${L7_GITHUB_TOKEN}"
    fi
    if [[ -n "${L7_USER_TOKEN_HASH}" ]]; then
      envfile_upsert_shell "${CONF_DIR}/.env" L7_USER_TOKEN_HASH "${L7_USER_TOKEN_HASH}"
    fi

    unset L7_GITHUB_TOKEN
    unset L7_GITHUB_TOKEN_HASH

    if [[ -n "${SHOULD_RESTART_HTTP_PROXY}" ]]; then
      # restart auth-proxy if already running
      auth_proxy_name=$(get_compose_container_name 'auth-proxy')
      "${cmd}" restart --running "${auth_proxy_name}" >/dev/null 2>/dev/null || true
    fi

  fi
}

start_compose () {
  (cd "${ROOT_DIR}" \
    && DOCKER_HOST="${DOCKER_HOST}" \
       CONTAINER_SOCKET="${CONTAINER_SOCKET}" \
      ${composecmd} up -d --wait >> "${LOG_DIR}/compose.log" 2>> "${LOG_DIR}/compose.err"
  )
}

build_start_compose () {
  (cd "${ROOT_DIR}" \
    && DOCKER_HOST="${DOCKER_HOST}" \
       CONTAINER_SOCKET="${CONTAINER_SOCKET}" \
      ${composecmd} up --build -d --wait
  )
}


########## MAIN

if [[ -n "${DEBUG}" ]]; then
  set -x
  RUN_ARGS="${RUN_ARGS} -e DEBUG=${DEBUG} "
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
if [[ -n "${BUILD_COMPOSE}" ]]; then
  build_start_compose
else
  start_compose
fi

${cmd} network ls --filter="name=${NETWORK_NAME}" | grep --quiet "${NETWORK_NAME}" >/dev/null 2>/dev/null
if (( $? != 0 )) ; then
  echo "Could not find expected ${CMD} network '${NETWORK_NAME}'. Run '$(basename "${composecmd}") up' in a separate terminal or supply the network name via the NETWORK_NAME env var." >&2
  exit 1
fi

container_id="$(${cmd} ps -f "name=${NAME}" -q || echo '')"

if [[ -n "${DEBUG}" ]]; then
  env
fi

if [[ -n "${container_id}" ]]; then
  entrypoint=${1:-${SHELL}}
  ${cmd} exec -it \
    -w "${CWD}" "${NAME}" \
    ${entrypoint} \
    "${@:2}"
else
  ${cmd} run --rm -i \
    --user 1000:1000 --userns=keep-id:uid=1000,gid=1000 \
    --mount type=bind,source="${LOCAL_DIR},target=/home/user/.local,U" \
    --mount type=bind,source="${CONF_DIR}/ssh.d,target=/home/user/.ssh/config.d,ro=true,U,Z" \
    --mount type=bind,source="${CONF_DIR}/git,target=/home/user/.config/git,ro=true,U,Z" \
    -v "${SRC_DIR}:${SRC_DIR}" \
    -v "${SRC_DIR}:/src" \
    -v "${NVIM_STATE_PATH}:/home/user/.local/state/nvim:z" \
    -v "${RESOLV_CONF_PATH}:/etc/resolv.conf:ro,z,U" \
    -w "${CWD}" \
    --mount type=tmpfs,tmpfs-size=2G,destination=/tmp,tmpfs-mode=0777 \
    -e "L7_COMPOSE_NETWORK_NAME_INTERNAL=${NETWORK_NAME}" \
    -e "L7_NVIM_STATE_PATH=${NVIM_STATE_PATH}" \
    -e "L7_NODE_CACHE_DIR=${NODE_CACHE_DIR}" \
    -e "L7_RESOLV_CONF_PATH=${RESOLV_CONF_PATH}" \
    -e "CONTAINER_HOST=tcp://10.7.9.2:2375" \
    -e "GO_RUNNER_IMAGE=${GO_RUNNER_IMAGE}" \
    -e "NODE_RUNNER_IMAGE=${NODE_RUNNER_IMAGE}" \
    -e "GPG_IMAGE=${GPG_IMAGE}" \
    -e HOME=/home/user \
    -e "SRC_DIR=${SRC_DIR}" \
    --network "${NETWORK_NAME}" \
    --network "${CONTROL_NETWORK_NAME}" \
    --dns "${CONTAINER_DNS}" \
    ${RUN_ARGS} \
    "${IMAGE}" \
    ${@:2}
fi
###
# --sysctl "net.ipv4.ping_group_range=1000 1000" \
