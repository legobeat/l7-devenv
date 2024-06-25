IMAGE_NAME :=
IMAGE_TAG  :=
NVIM_IMAGE_NAME := localhost/l7/nvim
NVIM_IMAGE_TAG  := latest
GPG_IMAGE_NAME := localhost/l7/gpg-vault
GPG_IMAGE_TAG  := pk
RUNNER_IMAGE_NAME := localhost/l7/node
RUNNER_IMAGE_TAG  := bookworm
AUTH_PROXY_IMAGE_NAME := localhost/l7/auth-proxy
AUTH_PROXY_IMAGE_TAG  := latest
CADDY_IMAGE_NAME := localhost/l7/caddy
CADDY_IMAGE_TAG  := latest
DNSMASQ_IMAGE_NAME := localhost/l7/dnsmasq
DNSMASQ_IMAGE_TAG  := latest
GO_RUNNER_IMAGE_NAME := localhost/l7/go
GO_RUNNER_IMAGE_TAG  := bookworm
USER_SHELL ?= /usr/bin/zsh
BUILD_OPTIONS :=
EXTRA_PKGS := zsh podman
UID:=$(shell id -u)
GID:=$(shell id -g)
CMD:=$(shell which podman || which docker)

install:
	./scripts/install-command.sh

image_auth_proxy : IMAGE_NAME = ${AUTH_PROXY_IMAGE_NAME}
image_auth_proxy : IMAGE_TAG = ${AUTH_PROXY_IMAGE_TAG}
image_auth_proxy:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './sidecars/git-auth-proxy/Dockerfile' \
		./sidecars/git-auth-proxy

image_caddy : IMAGE_NAME = ${CADDY_IMAGE_NAME}
image_caddy : IMAGE_TAG = ${CADDY_IMAGE_TAG}
image_caddy:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './sidecars/caddy/Containerfile' \
		./sidecars/caddy

image_dnsmasq: IMAGE_NAME = ${DNSMASQ_IMAGE_NAME}
image_dnsmasq: IMAGE_TAG = ${DNSMASQ_IMAGE_TAG}
image_dnsmasq:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './sidecars/dnsmasq/Containerfile' \
		./sidecars/dnsmasq

image_gpg_pk : IMAGE_NAME = ${GPG_IMAGE_NAME}
image_gpg_pk : IMAGE_TAG = ${GPG_IMAGE_TAG}
image_gpg_pk:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './sidecars/gpg-vault-pk/Containerfile' \
		.
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}-debian" \
		-f './sidecars/gpg-vault-pk/Containerfile.debian' \
		.

image_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
image_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
image_nvim : submodules image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "EXTRA_PKGS=${EXTRA_PKGS}" \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './Containerfile' \
		.
### GOLANG RUNNERS
image_runner_go_1.20 : IMAGE_NAME = ${GO_RUNNER_IMAGE_NAME}
image_runner_go_1.20 : IMAGE_TAG = ${GO_RUNNER_IMAGE_TAG}
image_runner_go_1.20: submodules
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		--build-arg "GO_VERSION=1.20" \
		-t "${IMAGE_NAME}:1.20-${IMAGE_TAG}" \
		-f './sidecars/go-runner/Containerfile' \

image_runner_go_1.20 : IMAGE_NAME = ${GO_RUNNER_IMAGE_NAME}
image_runner_go_1.20 : IMAGE_TAG = ${GO_RUNNER_IMAGE_TAG}
image_runner_go: image_runner_go_1.20
	${CMD tag \
		"${IMAGE_NAME}:1.20-${IMAGE_TAG} \
	    "${IMAGE_NAME}:${IMAGE_TAG}"


### NODE RUNNERS

image_runner_node_18 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_18 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_18: submodules image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		--build-arg "NODE_VERSION=18" \
		--build-arg "NODE_OPTIONS='--trace-warnings'" \
		-t "${IMAGE_NAME}:18-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \
		.
image_runner_node_20 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_20 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_20: submodules image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		--build-arg "NODE_VERSION=20" \
		-t "${IMAGE_NAME}:20-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \
		.
image_runner_node_22 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_22 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_22: submodules image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		--build-arg "NODE_VERSION=22" \
		-t "${IMAGE_NAME}:22-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \
		.

# with CocoaPods for iOS React Native dev
image_runner_node_ios : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_ios : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_ios: submodules image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		--build-arg "NODE_VERSION=20" \
		-t "${IMAGE_NAME}:ios-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile.ios' \
		.

image_runner_node_all: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_all: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_all: image_runner_node_20 image_runner_node_18 image_runner_node_22 # image_runner_node_ios
	${CMD} tag \
		"${IMAGE_NAME}:20-${IMAGE_TAG}" \
	    "${IMAGE_NAME}:${IMAGE_TAG}"

image_runner_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node: image_runner_node_20 # image_runner_node_18 image_runner_node_22 image_runner_node_ios
	${CMD} tag \
		"${IMAGE_NAME}:20-${IMAGE_TAG}" \
	    "${IMAGE_NAME}:${IMAGE_TAG}"

test_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
test_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
test_nvim: # image_nvim
	${CMD} run --rm -it \
		--entrypoint sh \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		-c 'nvim --version'

test_gpg_pk: IMAGE_NAME = ${GPG_IMAGE_NAME}
test_gpg_pk: IMAGE_TAG = ${GPG_IMAGE_TAG}
test_gpg_pk: # image_gpg_pk
	${CMD} run --rm -it \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		gpg --version

test_runner_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
test_runner_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
test_runner_node: # image_runner_node
	${CMD} run --rm -it \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		-c 'node --version'

# inspect jobs here just for ci, not really useful otherwise

inspect_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
inspect_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
inspect_nvim: # image_nvim
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_gpg_pk: IMAGE_NAME = ${GPG_IMAGE_NAME}
inspect_gpg_pk: IMAGE_TAG = ${GPG_IMAGE_TAG}
inspect_gpg_pk: # image_gpg_pk
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_runner_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
inspect_runner_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
inspect_runner_node: # image_runner_node
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

submodules:
	@git submodule update --checkout --init --recursive --rebase

images: image_caddy image_dnsmasq image_nvim image_runner_node image_gpg_pk

test: test_nvim test_runner_node test_gpg_pk
