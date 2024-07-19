ARG NODE_VERSION=20
ARG BASE_IMAGE=localhost/l7/node:${NODE_VERSION}-bookworm
ARG BUILDER_IMAGE=${BASE_IMAGE}
FROM ${BUILDER_IMAGE} AS tsserver-builder

USER root
COPY --chown=1002:1002 contrib/typescript-language-server /build/typescript-language-server
RUN mkdir -p /out /build/typescript-language-server  /tmp/1002-home \
  && chmod 777 /out /build/typescript-language-server  /tmp/1002-home \
  && chown 1002:1002 /out /build/typescript-language-server /tmp/1002-home

ENV HOME=/tmp/1002-home
USER 1002:1002

# build, pack, and install typescript-language-server
RUN set -x &&  cd /build/typescript-language-server \
  && yarn1 install --frozen-lockfile \
  && yarn1 build \
  && yarn1 pack \
  && cd /out \
  && npm10 i /build/typescript-language-server/*.t*gz \
  && rm -rf /tmp/1002-home /build/typescript-language-server/*.t*gz

FROM ${BASE_IMAGE}

USER root
COPY --from=tsserver-builder --chown=2:2 /out/node_modules/ /usr/local/lib/node_modules/

# restore symlink which can get messed up by COPY; effective .mjs extension is important for node
RUN ln -sf \
    /usr/local/lib/node_modules/typescript-language-server/lib/cli.mjs \
    /usr/local/lib/node_modules/.bin/typescript-language-server \
  && ln -sf /usr/local/lib/node_modules/typescript-language-server/lib/cli.mjs \
    /usr/local/bin/

ARG UID=1000
ARG GID=1000
USER ${UID}:${GID}

ENTRYPOINT [ "typescript-language-server", "--stdio" ]
