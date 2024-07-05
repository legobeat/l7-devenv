# syntax=docker/dockerfile:1.4-labs
ARG BASE_IMAGE=localhost/l7/alpine:3.20
ARG CADDY_IMAGE=localhost/l7/caddy:latest
FROM alpine:3.20 AS base


# EXTRA_BASE_PKGS get installed in both build and runtime. Example of useful packages:
### golang LSP support
## ARG EXTRA_PKGS='go golang-x-tools-gopls'
ARG EXTRA_BASE_PKGS=''

RUN apk add --no-cache \
     bash \
     curl wget jq tar \
     git \
     neovim \
     $EXTRA_BASE_PKGS \
  && ln -sf nvim /usr/bin/vim

# this assumes we already have a locally built caddy image
# the image contains a pregenerated ca root cert for mitm, which we copy here
# TODO: provide a nicer way to manage the rootcert
FROM ${CADDY_IMAGE} AS fwdproxy
#######################
##### FINAL IMAGE #####
FROM base

ARG EXTRA_PKGS="iproute2"

ARG HOME=/home/user
ENV HOME=${HOME}
ARG SHELL=/bin/bash
ARG UID=1000
ARG GID=1000

WORKDIR ${HOME}

RUN apk add --no-cache \
    openssl \
    envsubst \
    # build-deps
    shadow \
    ${EXTRA_PKGS} \
  && ln -sf nvim /usr/bin/vim \

  # create user entry or podman will mess up /etc/passwd entry
  && bash -c "groupadd -g ${GID} userz || true" \
  && bash -c "useradd -u ${UID} -g ${GID} -d /home/user -m user -s "${SHELL}" && chown -R ${UID}:${GID} /home/user || true" \
  && apk del shadow


COPY --chmod=755 --chown=root contrib/bin/* contrib/*/bin/*       /usr/local/bin/
ARG NODE_BINS="npm7 npm9 npm10 pnpm9 yarn1 yarn3 yarn4     allow-scripts corepack glob lavamoat-ls mkdirp node-gyp node-which nopt npx pnpx resolve semver yarn-deduplicate"
RUN for bin in ${NODE_BINS}; do ln -s l7-run-node "/usr/local/bin/${bin}"; done

COPY --chown=${UID}:${GID} skel/ /home/user/

# default trust github.com known ssh key
COPY contrib/data/ssh_known_hosts /etc/ssh/ssh_known_hosts

COPY --from=fwdproxy \
  --chmod=444 \
  /data/caddy/pki/authorities/local/root.crt \
  /usr/local/share/ca-certificates/l7-fwd-proxy.crt

RUN cat /usr/local/share/ca-certificates/l7-fwd-proxy.crt >> /etc/ssl/certs/ca-certificates.crt \
  && cat /home/user/.env >> /etc/profile \
  # podman quirk: `COPY --from` messes up ownership so rechown needs to come last
  && chown -R ${UID}:${GID} \
    /home/user

USER ${UID}:${GID}
WORKDIR /src
ENTRYPOINT ${SHELL}

