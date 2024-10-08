#!/bin/bash

########## FUNCTIONS

user_config () {
  set -a # export variables
  ### dirs
  CONF_DIR="${CONF_DIR:-${HOME}/.config/l7ide/config}"
  LOCAL_DIR="${LOCAL_DIR:-${HOME}/.local/share/l7ide/local}"
  NODE_CACHE_DIR="${NODE_CACHE_DIR:-$(mktemp -d -t l7-node-cache.XXXX --tmpdir)}"

  # .env is for current running environment; env gets loaded in container
  if [[ -f "${ROOT_DIR}/.env" ]]; then
    . "${ROOT_DIR}/.env"
  fi
  if [[ -f "${CONF_DIR}/.env" ]]; then
    . "${CONF_DIR}/.env"
  fi

  SRC_DIR="${SRC_DIR:-${L7_SRC_DIR:-$(pwd)}}"
  SRC_DIR_OPTS="${SRC_DIR_OPTS:-:rshared,nosuid}"
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

vnc_config () {
  set -a # export variables
  mkdir -p "${LOCAL_DIR}/vnc"
  if [[ -n "${L7_ENABLE_VNC}" ]]; then
    VNC_NETWORK_NAME=${VNC_NETWORK_NAME:-l7_dev_vnc}
    RUN_ARGS="${RUN_ARGS} --network ${VNC_NETWORK_NAME}:ip=10.7.9.50"
    if [[ ! -f "${LOCAL_DIR}/vnc/admin_vncpasswd" ]]; then
      VNC_PASSWORD="$(head -c 1000 /dev/random | base32 | head -c8)"
      VNC_VIEW_PASSWORD="$(head -c 1000 /dev/random | base32 | head -c8)"
      #echo "${VNC_PASSWORD}\n${VNC_VIEW_PASSWORD}" > "${LOCAL_DIR}/vnc/vncpasswd"
      # TODO: better secrets handling
      echo "${VNC_PASSWORD}" > "${LOCAL_DIR}/vnc/admin_vncpasswd"
      echo "${VNC_VIEW_PASSWORD}" > "${LOCAL_DIR}/vnc/view_vncpasswd"
      #echo "Generated new VNC passwords:\n  - Admin: ${VNC_PASSWORD}\n  - View: ${VNC_VIEW_PASSWORD}\n\n" >&2
      cat <<EOT >&2
Generated new VNC passwords:
  - Admin: ${VNC_PASSWORD}
  - View: ${VNC_VIEW_PASSWORD}

EOT
    fi
  fi
}

runtime_config () {
  set -a # export variables
  export PODMAN_COMPOSE_WARNING_LOGS=false
  export UID
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
  export CONTAINERS_CONF_OVERRIDE="${ROOT_DIR}/compose/.containers-override.conf"

  # compose, used for imags and leaked into de
  # CONTAINER_SOCKET is proxied into the container and used by dev-shell container to run imags
  export CONTAINER_SOCKET="${CONTAINER_SOCKET:-${XDG_RUNTIME_DIR}/podman/podman.sock}"
  if [[ -z "${CONTAINER_SOCKET}" || ! -S "${CONTAINER_SOCKET}" ]]; then
    CONTAINER_SOCKET="${CONTAINER_SOCKET:-/var/run/docker.sock}"
  fi

  if [[ ! -S "${CONTAINER_SOCKET}" ]]; then
    echo "Error: Could not detect container socket. This can be worked around by setting the CONTAINER_SOCKET env var. File this as a bug."
    exit 1
  fi

  NETWORK_NAME="${NETWORK_NAME:-${COMPOSE_NETWORK_NAME:-l7_dev_internal}}"

  ### run args
  ### TODO: use `compose run` for dev-shell in order to be able to forward these
  #if [[ -n "${SSH_SOCKET}" ]]; then
  #  RUN_ARGS="${RUN_ARGS} -v ${SSH_SOCKET}:${HOME}/.ssh/SSH_AUTH_SOCK -e SSH_AUTH_SOCK=${HOME}/.ssh/SSH_AUTH_SOCK"
  #fi
  if [[ -n "${NAME}" ]]; then
  #  RUN_ARGS="${RUN_ARGS} --name ${NAME} --hostname ${NAME}"
    RUN_ARGS="${RUN_ARGS} --name=${NAME}"
  fi

  # TODO
  #if [[ -f "${ROOT_DIR}/env" ]]; then
  #  RUN_ARGS="${RUN_ARGS} --env-file ${ROOT_DIR}/env"
  #fi
  #if [[ -f "${CONF_DIR}/env" ]]; then
  #  RUN_ARGS="${RUN_ARGS} --env-file ${CONF_DIR}/env"
  #fi
  #if [[ "${L7_DISABLE_SELINUX}" == "1" ]]; then
  #  RUN_ARGS="${RUN_ARGS} --security-opt=label=disable -e L7_DISABLE_SELINUX=1"
  #fi
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
  # TODO: set log-level when supported in repo docker-compose, or containerize docker-compose
  # echo "${composecmd} --progress=quiet --project-directory=${ROOT_DIR} --log-level=${COMPOSE_LOG_LEVEL:-error}"
  echo "${composecmd} --progress=quiet --project-directory=${ROOT_DIR}"
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
      SHOULD_RESTART_AUTH_PROXY=1
    fi
    if [[ -z "${L7_USER_TOKEN_HASH}" ]]; then
      export L7_USER_TOKEN="$(head -c 1000 /dev/random | base32 | head -c32)"
      msg="${msg}Generated new internal gh auth token. " >&2
      export L7_USER_TOKEN_HASH="$(mkpasswd -m sha512crypt "${L7_USER_TOKEN}")"
      SHOULD_RESTART_AUTH_PROXY=1
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

    if [[ -n "${SHOULD_RESTART_AUTH_PROXY}" ]]; then
      "${composecmd}" restart --no-deps 'auth-proxy'  >/dev/null 2>/dev/null || true
      unset  SHOULD_RESTART_AUTH_PROXY
    fi
  fi
}

start_compose () {
  (cd "${ROOT_DIR}" \
    && DOCKER_HOST="${DOCKER_HOST:-unix://${CONTAINER_SOCKET}}" \
       CONTAINER_SOCKET="${CONTAINER_SOCKET}" \
      ${composecmd} up -d --wait dev-shell >> "${LOG_DIR}/compose.log" 2>> "${LOG_DIR}/compose.err"
  )
}

########## MAIN

if [[ -n "${DEBUG}" ]]; then
  set -x
  RUN_ARGS="${RUN_ARGS} -e DEBUG=${DEBUG} "
fi

# default workdir to pwd if within SRC_DIR or /src; otherwise SRC_DIR
if [ -z "${CWD}" ]; then
  case "${PWD}/" in
    ${SRC_DIR}/*) export CWD="${PWD}";;
    /src/*)       export CWD="${PWD}";;
    *)            export CWD="${SRC_DIR}";;
  esac
fi

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script/1482133#1482133
export ROOT_DIR="${ROOT_DIR:-$(dirname -- "$( readlink -f -- "$0"; )")}"

user_config
runtime_config
configure_gh_token
vnc_config
start_compose

${cmd} network ls --filter="name=${NETWORK_NAME}" | grep --quiet "${NETWORK_NAME}" >/dev/null 2>/dev/null
if (( $? != 0 )) ; then
  echo "Could not find expected ${CMD} network '${NETWORK_NAME}'. Run '$(basename "${composecmd}") up' in a separate terminal or supply the network name via the NETWORK_NAME env var." >&2
  exit 1
fi

if [[ -n "${DEBUG}" ]]; then
  env | sort
fi

entrypoint="${1:-${USER_SHELL:-/bin/zsh}}"

# allow explicitly execing into named container
EXEC_ARGS=${EXEC_ARGS:--it}
if [[ -n "${L7_NAME:-${NAME}}" ]]; then
  L7_CNTR="$(${cmd} ps -f "name=${L7_NAME:-${NAME}}" -q || echo '')"
fi
if [[ -n "${L7_CNTR}" ]]; then
  ${cmd} exec \
    -w "${CWD}" \
    ${EXEC_ARGS} \
    "${L7_CNTR}" \
    "${entrypoint}" \
    "${@:2}"
  exit $?
#else
#  # fall back to compose
#  echo "Warning: Could not determine container id; falling back to compose. This is probably a bug." >&2
#  ${composecmd} exec \
#    -w "${CWD}" \
#    ${EXEC_ARGS} \
#    "dev-shell" \
#    ${entrypoint} \
#    "${@:2}"
#  exit $?
fi

${composecmd} run \
  --rm \
  -w "${CWD}" \
  "--entrypoint=${entrypoint}" \
  ${RUN_ARGS} \
  "${L7_COMPOSE_SVC:-"dev-shell"}" \
  "${@:2}"
