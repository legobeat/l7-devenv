IMAGE_NAME := localhost/l7/nvim
IMAGE_TAG  := latest
RUNNER_IMAGE_NAME := localhost/l7/node
RUNNER_IMAGE_TAG  := 20-bookworm
USER_SHELL ?= /usr/bin/zsh
BUILD_OPTIONS :=
EXTRA_PKGS := zsh podman
UID:=$(shell id -u)
GID:=$(shell id -g)
CMD:=$(shell which podman || which docker)

image_nvim:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "EXTRA_PKGS=${EXTRA_PKGS}" \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './Containerfile' \
		.

image_runner:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		-t "${RUNNER_IMAGE_NAME}:${RUNNER_IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \
		.

test:
	@echo TODO: tests
