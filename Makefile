IMAGE_NAME :=
IMAGE_TAG  :=
NVIM_IMAGE_NAME := localhost/l7/nvim
NVIM_IMAGE_TAG  := latest
GPG_IMAGE_NAME := localhost/l7/gpg-vault
GPG_IMAGE_TAG  := pk
RUNNER_IMAGE_NAME := localhost/l7/node
RUNNER_IMAGE_TAG  := 20-bookworm
USER_SHELL ?= /usr/bin/zsh
BUILD_OPTIONS :=
EXTRA_PKGS := zsh podman
UID:=$(shell id -u)
GID:=$(shell id -g)
CMD:=$(shell which podman || which docker)

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

image_runner : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner: submodules
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \
		.

submodules:
	@git submodule update --checkout --init --recursive --rebase

test: test_nvim test_runner

test_nvim:
	@echo TODO: nvim image tests

test_runner:
	@echo TODO: node-runner image tests

images: image_gpg_pk image_runner image_nvim
