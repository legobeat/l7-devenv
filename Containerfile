# syntax=docker/dockerfile:1.4-labs
FROM registry.fedoraproject.org/fedora-minimal:40 AS base

RUN microdnf -y update

# EXTRA_BASE_PKGS get installed in both build and runtime. Example of useful packages:
### golang LSP support
## ARG EXTRA_PKGS='go golang-x-tools-gopls'
ARG EXTRA_BASE_PKGS=''

RUN microdnf -y install --setopt=install_weak_deps=False \
    make automake gcc gcc-c++ cpp binutils patch  \
    curl wget jq yq moreutils tar \
    git git-lfs openssh-clients gnupg2 \
    libnotify \
    man-db \
    neovim lua python3-neovim \
    lua-lunitx \
    nodejs typescript \
    $EXTRA_BASE_PKGS \
  && ln -sf nvim /usr/bin/vim

##### NEOVIM PLUGINS BUILDER #####
FROM base AS nvim-builder

ARG EXTRA_BUILD_PKGS=''
RUN microdnf -y install --setopt=install_weak_deps=False \
    binutils patch \
    cargo \
    luarocks lua-lunitx \
    nodejs typescript \
    ${EXTRA_BUILD_PKGS}

WORKDIR /etc/xdg/nvim/pack/build-l7ide/start
COPY --chown=1001:1001 contrib/nvim-plugins/ ./
RUN mkdir -p /out /home/nvim-builder \
  && chown -R 1001:1001 /home/nvim-builder

USER 1001

# enable/disable treesitter language parsers. These are fetched remotely.
ARG TREESITTER_INSTALL='bash c dockerfile hcl javascript lua markdown nix python ruby typescript vim vimdoc yaml'
ARG BUILD_STYLUA_VERSION=0.20.0

ENV HOME=/home/nvim-builder
RUN luarocks --lua-version=5.1 install vusted
# make nvim plugins, but skip running long-running test-only makefiles
RUN cargo install stylua --version "${BUILD_STYLUA_VERSION}" --locked --all-features \
  && PATH=/home/nvim-builder/.cargo/bin:${PATH} bash -c 'find . -maxdepth 1 -mindepth 1 -type d ! -name "plenary.nvim" ! -name "neo-tree.nvim" | xargs -I{} -P8 bash -c "cd {}; make -j4 build || make -j4 || true"'
RUN nvim --headless \
    -c 'packadd nvim-treesitter' \
    -c 'packloadall' \
    -c "TSEnable ${TREESITTER_INSTALL}" \
    -c "TSUpdateSync ${TREESITTER_INSTALL}" \
    -c "TSEnable ${TREESITTER_INSTALL}" \
    -c q
WORKDIR /out
USER root
RUN mkdir -p /out/plugins \
  && mv /etc/xdg/nvim/pack/build-l7ide/start/* /out/plugins/

##### TYPESCRIPT-LANGUAGE-SERVER BUILDER #####
FROM base AS tsserver-builder

ENV NODE_OPTIONS='--no-network-family-autoselection --trace-warnings'

RUN microdnf -y install --setopt=install_weak_deps=False \
    nodejs npm typescript yarnpkg \
  && mkdir -p /out \
  && chown 1002:1002 /out

COPY --chown=1002:1002 contrib/typescript-language-server/ /build/typescript-language-server/

WORKDIR /build/typescript-language-server
RUN chown -R 1002:1002 .

USER 1002
ENV HOME=/tmp/1002-home

RUN yarn install --frozen-lockfile --network-concurrency 10 \
  && yarn build \
  && yarn pack
WORKDIR /out
RUN npm i /build/typescript-language-server/*.t*gz && ls

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
## ARG EXTRA_PKGS='sudo' # TODO: needs some more fiddling with uidmap to work with rootless podman
## ARG EXTRA_PKGS='tree-sitter-cli' # repo version errors right now? try again later
## ARG EXTRA_PKGS='podman docker-compose' # TODO: wire up docker socket

ARG EXTRA_PKGS='bat zsh podman'

RUN microdnf -y install --setopt=install_weak_deps=False \
    tree fzf ripgrep \
    sshpass \
    hub gh tig \
    libnotify \
    man-db \
    screen \
    w3m \
    which procps-ng \
    ${EXTRA_PKGS} \
  && ln -sf nvim /usr/bin/vim


COPY --from=nvim-builder     --chown=2:2 /out/plugins /etc/xdg/nvim/pack/l7ide/start
COPY --from=tsserver-builder --chown=2:2 /out/node_modules/ /usr/lib/node_modules/
COPY contrib/bin/*        /usr/local/bin/
COPY contrib/*/bin/*      /usr/local/bin/

ARG HOME=/home/user
ENV HOME=${HOME}
ARG SHELL=/usr/bin/bash
ARG UID=1000
ARG GID=1000

# create user entry or podman will mess up /etc/passwd entry
# also grant passwordless sudo
# this means image will have to be rebuilt with --build-arg UID=$(id -u) if runtime user has different UID from default 1000
RUN  bash -c "groupadd -g ${GID} userz || true" \
  && bash -c "useradd -u ${UID} -g ${GID} -d /home/user -m user -s "${SHELL}" && chown -R ${UID}:${GID} /home/user || true" \
  && usermod -G wheel -a $(id -un ${UID}) \
  && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers


# allow accessing mounted container runtime socket ("docker-in-docker"/"podman-in-podman"/"d-i-p")
# https://github.com/containers/image_build/blob/main/podman/Containerfile
RUN usermod --add-subuids 1001-64535    --add-subgids 1001-64535 user \
 && usermod --add-subuids 1-999         --add-subgids 1-999      user \
 && setcap cap_setuid=+eip /usr/bin/newuidmap \
 && setcap cap_setgid=+eip /usr/bin/newgidmap

WORKDIR ${HOME}

# https://github.com/gabyx/container-nesting/blob/7efbd79707e1be366bee462f6200443ca23bc077/src/podman/container/Containerfile#L46
RUN mkdir -p /etc/containers .config/containers && \
    sed -e 's|^#mount_program|mount_program|g' \
           -e '/additionalimage.*/a "/var/lib/shared",' \
           -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
           /usr/share/containers/storage.conf \
           > /etc/containers/storage.conf && \
    sed -e 's|^graphroot|#graphroot|g' \
        -e 's|^runroot|#runroot|g' \
           /etc/containers/storage.conf > .config/containers/storage.conf
COPY config/containers/containers.conf /etc/containers/containers.conf

COPY --chown=${UID}:${GID} config/bash_profile .bash_profile
COPY --chown=${UID}:${GID} config/bashrc       .bashrc
COPY --chown=${UID}:${GID} config/env          .env
COPY --chown=${UID}:${GID} config/gitconfig    .gitconfig
COPY --chown=${UID}:${GID} config/gh.yml        gh/config.yml
COPY --chown=${UID}:${GID} config/profile      .profile
COPY --chown=${UID}:${GID} config/ssh          .ssh/config
# COPY config/ssh         /etc/ssh/ssh_config.d/60-user.conf
COPY --chown=${UID}:${GID} config/zshrc        .zshrc
# TODO: see if we can get everything loading right without using .config so users can mount it as volume
# ...just ~/.vimrc?
COPY --chown=${UID}:${GID} config/nvim         .config/nvim

RUN cat /home/user/.env >> /etc/profile

# treesitter needs write to parsers dirs
RUN chown -R ${UID}:${GID} \
  .config \
  /etc/xdg/nvim/pack/l7ide/start/nvim-treesitter/parser{-info,}

USER ${UID}
WORKDIR /home/user/src
