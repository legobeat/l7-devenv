# syntax=docker/dockerfile:1.4-labs
FROM registry.fedoraproject.org/fedora-minimal:40 AS base


# EXTRA_BASE_PKGS get installed in both build and runtime. Example of useful packages:
### golang LSP support
## ARG EXTRA_PKGS='go golang-x-tools-gopls'
ARG EXTRA_BASE_PKGS=''

RUN microdnf -y update \
  && microdnf -y install --setopt=install_weak_deps=False \
     make automake gcc gcc-c++ cpp binutils patch  \
     curl wget jq yq moreutils tar \
     git git-lfs openssh-clients gnupg2 \
     libnotify \
     man-db \
     neovim lua python3-neovim \
     nodejs typescript \
     $EXTRA_BASE_PKGS \
  && ln -sf nvim /usr/bin/vim

##################################
##### NEOVIM PLUGINS BUILDER #####

FROM base AS nvim-builder

# enable/disable treesitter language parsers. These are fetched remotely.
ARG TREESITTER_INSTALL='bash c dockerfile hcl javascript lua make markdown nix python ruby typescript vim vimdoc yaml'
ENV HOME=/tmp/1001-home

# TODO: not supported on podman ubuntu-22.03
# Using RUN --mount is more efficient than COPY for stuff only used during image build.
# RUN --mount=source=contrib/nvim-plugins,target=/etc/xdg/nvim/pack/build-l7ide/start,rw=true \
COPY contrib/nvim-plugins /etc/xdg/nvim/pack/build-l7ide/start
RUN \
  microdnf install -y lua-lunitx \
  && cd /etc/xdg/nvim/pack/build-l7ide/start \
  # make nvim plugins, but skip running long-running test-only makefiles
  # TODO: disabled for now; run separately in tests
  && bash -c 'find . -maxdepth 1 -mindepth 1 -type d ! -name "plenary.nvim" ! -name "neo-tree.nvim" | xargs -I{} echo SKIPPING: bash -c "cd {}; make -j4 build || make -j4 || true"' >&2 \
  && nvim --headless \
     -c 'packadd nvim-treesitter' \
     -c 'packloadall' \
     -c "TSEnable ${TREESITTER_INSTALL}" \
     -c "TSUpdateSync ${TREESITTER_INSTALL}" \
     -c "TSEnable ${TREESITTER_INSTALL}" \
     -c q \
  && mkdir -p /out/plugins \
  && cd /out \
  && microdnf remove -y lua-lunitx \
  && microdnf clean all \
  && cp -a /etc/xdg/nvim/pack/build-l7ide/start/* /out/plugins/


##############################################
##### TYPESCRIPT-LANGUAGE-SERVER BUILDER #####

FROM base AS tsserver-builder

ENV NODE_OPTIONS='--no-network-family-autoselection --trace-warnings'
ENV HOME=/tmp/1002-home

# TODO: not supported on podman ubuntu-22.03
# RUN --mount=source=contrib/typescript-language-server,target=/build/typescript-language-server,rw=true \
COPY contrib/typescript-language-server /build/typescript-language-server
RUN \
  microdnf -y install --setopt=install_weak_deps=False \
    npm yarnpkg \
  && mkdir -p /out /build/typescript-language-server \
  # build, pack, and install typescript-language-server
  && cd /build/typescript-language-server  \
  && yarn install --frozen-lockfile --network-concurrency 10 \
  && yarn build \
  && yarn pack \
  && cd /out \
  && npm i /build/typescript-language-server/*.t*gz \
  && microdnf remove -y npm yarnpkg \
  && microdnf clean all \
  && rm -rf /tmp/1002-home /build/typescript-language-server/*.t*gz

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
## ARG EXTRA_PKGS='sudo' # TODO: needs some more fiddling with uidmap to work with rootless podman
## ARG EXTRA_PKGS='tree-sitter-cli' # repo version errors right now? try again later
## ARG EXTRA_PKGS='podman docker-compose' # TODO: wire up docker socket

ARG EXTRA_PKGS='bat zsh podman'

COPY --from=nvim-builder     --chown=2:2 /out/plugins /etc/xdg/nvim/pack/l7ide/start
COPY --from=tsserver-builder --chown=2:2 /out/node_modules/ /usr/lib/node_modules/
COPY contrib/bin/* contrib/*/bin/*       /usr/local/bin/

ARG HOME=/home/user
ENV HOME=${HOME}
ARG SHELL=/usr/bin/zsh
ARG UID=1000
ARG GID=1000

WORKDIR ${HOME}

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
  && ln -sf nvim /usr/bin/vim \

  # create user entry or podman will mess up /etc/passwd entry
  # also grant passwordless sudo
  # this means image will have to be rebuilt with --build-arg UID=$(id -u) if runtime user has different UID from default 1000
  && bash -c "groupadd -g ${GID} userz || true" \
  && bash -c "useradd -u ${UID} -g ${GID} -d /home/user -m user -s "${SHELL}" && chown -R ${UID}:${GID} /home/user || true" \
  && usermod -G wheel -a $(id -un ${UID}) \
  && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
  # allow accessing mounted container runtime socket ("docker-in-docker"/"podman-in-podman"/"d-i-p")
  # https://github.com/containers/image_build/blob/main/podman/Containerfile
  && usermod --add-subuids 1001-64535    --add-subgids 1001-64535 user \
  && usermod --add-subuids 1-999         --add-subgids 1-999      user \
  && setcap cap_setuid=+eip /usr/bin/newuidmap \
  && setcap cap_setgid=+eip /usr/bin/newgidmap \
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
  && microdnf -y install podman fuse-overlayfs openssh-clients --exclude container-selinux \
  && microdnf clean all

COPY skel/.config/containers/containers.conf /etc/containers/containers.conf
COPY --chown=${UID}:${GID} skel/ /home/user/

RUN cat /home/user/.env >> /etc/profile \
  && chown -R ${UID}:${GID} \
    /home/user \
    # treesitter needs write to parsers dirs
    /etc/xdg/nvim/pack/l7ide/start/nvim-treesitter/parser{-info,}

USER ${UID}
WORKDIR /src
ENTRYPOINT ${SHELL}
