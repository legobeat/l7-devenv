IMAGE_NAME :=
IMAGE_TAG  :=
NVIM_IMAGE_NAME := localhost/l7/nvim
NVIM_IMAGE_TAG  := latest
GPG_IMAGE_NAME := localhost/l7/gpg-vault
GPG_IMAGE_TAG  := pk
RUNNER_IMAGE_NAME := localhost/l7/node
RUNNER_IMAGE_TAG  := bookworm
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
image_nvim : submodules
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
image_runner_go: image_runner_go_1.20 # image_runner_node_16 image_runner_node_18 image_runner_node_22
	${CMD tag \
		"${IMAGE_NAME}:1.20-${IMAGE_TAG} \
	    "${IMAGE_NAME}:${IMAGE_TAG}"


### NODE RUNNERS

image_runner_node_16 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_16 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_16: submodules
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		--build-arg "NODE_VERSION=16" \
		--build-arg "NODE_OPTIONS='--trace-warnings'" \
		-t "${IMAGE_NAME}:16-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \
		.
image_runner_node_18 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_18 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_18: submodules
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
image_runner_node_20: submodules
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
image_runner_node_22: submodules
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		--build-arg "NODE_VERSION=22" \
		-t "${IMAGE_NAME}:22-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \

# with CocoaPos for iOS React Native dev
image_runner_node_ios : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_ios : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_ios: submodules
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
image_runner_node_all: image_runner_node_20 image_runner_node_16 image_runner_node_18 image_runner_node_22 # image_runner_node_ios
	${CMD} tag \
		"${IMAGE_NAME}:20-${IMAGE_TAG}" \
	    "${IMAGE_NAME}:${IMAGE_TAG}"

image_runner_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node: image_runner_node_20 # image_runner_node_16 image_runner_node_18 image_runner_node_22 image_runner_node_ios
	${CMD} tag \
		"${IMAGE_NAME}:20-${IMAGE_TAG}" \
	    "${IMAGE_NAME}:${IMAGE_TAG}"

submodules:
	@git submodule update --checkout --init --recursive --rebase

test: test_nvim test_runner

test_nvim:
	@echo TODO: nvim image tests

test_runner:
	@echo TODO: node-runner image tests

images: image_gpg_pk image_runner_node image_nvim
