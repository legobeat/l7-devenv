ARG GO_VERSION=1.20
FROM localhost/l7/go:${GO_VERSION}-bookworm

USER root
RUN go install golang.org/x/tools/gopls@v0.15.3

ARG UID=1000
ARG GID=1000
USER ${UID}:${GID}
