IMAGE_NAME:=localhost/l7/nvim
IMAGE_TAG:=latest
USER_SHELL ?= ${SHELL}
EXTRA_PKGS := 'zsh podman'
UID:=$(shell id -u)
GID:=$(shell id -g)
CMD:=$(shell which podman || which docker)

image_nvim:
	${CMD} build \
		--build-arg "EXTRA_PKGS=${EXTRA_PKGS}" \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "UID=${UID}" \
		--build-arg "GID=${GID}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		.
test:
	@echo TODO: tests
