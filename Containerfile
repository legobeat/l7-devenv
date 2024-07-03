# syntax=docker/dockerfile:1.4-labs
ARG CADDY_IMAGE=localhost/l7/caddy:latest
FROM registry.fedoraproject.org/fedora-minimal:40 AS base


# EXTRA_BASE_PKGS get installed in both build and runtime. Example of useful packages:
### golang LSP support
## ARG EXTRA_PKGS='go golang-x-tools-gopls'
ARG EXTRA_BASE_PKGS=''

RUN microdnf -y update \
  && microdnf -y install --setopt=install_weak_deps=False \
     make automake patch \
     curl wget jq yq moreutils tar \
     git gnupg2 \
     neovim python3-neovim \
     $EXTRA_BASE_PKGS \
  && ln -sf nvim /usr/bin/vim

##################################
##### NEOVIM PLUGINS BUILDER #####

FROM base AS nvim-builder

ARG EXTRA_BUILD_PKGS=''
# enable/disable treesitter language parsers. These are fetched remotely.
ARG TREESITTER_INSTALL='bash c dockerfile hcl javascript lua make markdown nix python ruby typescript vim vimdoc yaml'
ENV HOME=/tmp/1001-home

# TODO: not supported on podman ubuntu-22.03
# Using RUN --mount is more efficient than COPY for stuff only used during image build.
# RUN --mount=source=contrib/nvim-plugins,target=/etc/xdg/nvim/pack/build-l7ide/start,rw=true \
COPY contrib/nvim-plugins /etc/xdg/nvim/pack/build-l7ide/start
RUN \
  microdnf install -y --setopt=install_weak_deps=False \
    # lua-lunitx binutils \
    lua \
    gcc gcc-c++ cpp \
    $EXTRA_BUILD_PKGS \
  && cd /etc/xdg/nvim/pack/build-l7ide/start \
  # install TreeSitter parsers
  && nvim --headless \
     -c 'packadd nvim-treesitter' \
     -c 'packloadall' \
     -c "TSEnable ${TREESITTER_INSTALL}" \
     -c "TSUpdateSync ${TREESITTER_INSTALL}" \
     -c "TSEnable ${TREESITTER_INSTALL}" \
     -c q \
  && mkdir -p /out/plugins \
  && cd /out \
  && microdnf clean all \
  && cp -a /etc/xdg/nvim/pack/build-l7ide/start/* /out/plugins/


# this assumes we already have a locally built caddy image
# the image contains a pregenerated ca root cert for mitm, which we copy here
# TODO: provide a nicer way to manage the rootcert
FROM ${CADDY_IMAGE} AS fwdproxy
#######################
##### FINAL IMAGE #####
FROM base

# EXTRA_PKGS get installed in final image. examples of useful extra packages:
### golang LSP support
## ARG EXTRA_PKGS='go golang-x-tools-gopls'
### secrets injection
## ARG EXTRA_PKGS='age pass gopass'
### TUI file managers
## ARG EXTRA_PKGS='ranger vifm'
### open links in host browser
## ARG EXTRA_PKGS='xdg-open'
### yes, you can integrate with system clipboard
## ARG EXTRA_PKGS='xsel xclip wl-clipboard'
## ARG EXTRA_PKGS='terminus-fonts fontawesome-fonts-all gdouros-symbola-fonts'
### monitoring etc, probably more useful on host
## ARG EXTRA_PKGS='htop sysstat ncdu net-tools'
### wip / not working / notes
## ARG EXTRA_PKGS='tree-sitter-cli' # repo version errors right now? try again later

ARG EXTRA_PKGS='bat'

ARG HOME=/home/user
ENV HOME=${HOME}
ARG SHELL=/usr/bin/zsh
ARG UID=1000
ARG GID=1000

WORKDIR ${HOME}

RUN microdnf -y install --setopt=install_weak_deps=False \
    diffutils tree fzf ripgrep \
    sshpass \
    git-lfs hub gh tig \
    libnotify \
    ip openssl procps-ng psmisc \
    man-db \
    podman-remote containers-common \
    # devenv-in-denvenv
    gettext-envsubst mkpasswd \
    screen \
    w3m \
    which \
    zsh \
    ${EXTRA_PKGS} \
  && ln -sf nvim /usr/bin/vim \

  # create user entry or podman will mess up /etc/passwd entry
  && bash -c "groupadd -g ${GID} userz || true" \
  && bash -c "useradd -u ${UID} -g ${GID} -d /home/user -m user -s "${SHELL}" && chown -R ${UID}:${GID} /home/user || true" \
  # https://github.com/gabyx/container-nesting/blob/7efbd79707e1be366bee462f6200443ca23bc077/src/podman/container/Containerfile#L46
  && mkdir -p /etc/containers .config/containers \
  && sed -e 's|^#mount_program|mount_program|g' \
         -e '/additionalimage.*/a "/var/lib/shared",' \
         -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
         /usr/share/containers/storage.conf \
         > /etc/containers/storage.conf \
  && sed -e 's|^graphroot|#graphroot|g' \
         -e 's|^runroot|#runroot|g' \
         /etc/containers/storage.conf > .config/containers/storage.conf \
  && rpm --setcaps shadow-utils 2>/dev/null \
  && microdnf -y install podman-remote fuse-overlayfs openssh-clients --exclude container-selinux \
  && microdnf clean all

COPY --from=nvim-builder --chown=2:2 \
  /out/plugins /etc/xdg/nvim/pack/l7ide/start
COPY --chmod=755 --chown=root contrib/bin/* contrib/*/bin/*       /usr/local/bin/
ARG NODE_BINS="allow-scripts corepack glob lavamoat-ls mkdirp node-gyp node-which nopt npx pnpx resolve semver yarn-deduplicate"
RUN for bin in ${NODE_BINS}; do ln -s l7-run-node "/usr/local/bin/${bin}"; done
ARG NPM_MAJORS="7 9 10"
RUN for v in ${NPM_MAJORS}; do ln -s npm "/usr/local/bin/npm${v}"; done
ARG YARN_MAJORS="1 3 4"
RUN for v in ${YARN_MAJORS}; do ln -s yarn "/usr/local/bin/yarn${v}"; done
ARG PNPM_MAJORS="9"
RUN for v in ${PNPM_MAJORS}; do ln -s pnpm "/usr/local/bin/pnpm${v}"; done

COPY skel/.config/containers/containers.conf /etc/containers/containers.conf
COPY --chown=${UID}:${GID} skel/ /home/user/

# default trust github.com known ssh key
COPY contrib/data/ssh_known_hosts /etc/ssh/ssh_known_hosts
# https://docs.fedoraproject.org/en-US/quick-docs/using-shared-system-certificates/
COPY --from=fwdproxy \
  --chmod=444 \
  /data/caddy/pki/authorities/local/root.crt \
  /etc/pki/ca-trust/source/anchors/l7-fwd-proxy.crt
RUN update-ca-trust \
  && cat /home/user/.env >> /etc/profile \
  # podman quirk: `COPY --from` messes up ownership so rechown needs to come last
  && chown -R ${UID}:${GID} \
    /home/user \
    # treesitter needs write to parsers dirs?
    /etc/xdg/nvim/pack/l7ide/start/nvim-treesitter/parser{-info,} \
  && ln -s \
    podman-remote /usr/bin/podman



USER ${UID}:${GID}
WORKDIR /src
ENTRYPOINT ${SHELL}
