SHELL := /bin/bash
IMAGE_NAME :=
IMAGE_TAG  :=
IMAGE_REPO := localhost/l7
NVIM_IMAGE_NAME := ${IMAGE_REPO}/nvim
NVIM_IMAGE_TAG  := latest
GPG_IMAGE_NAME := ${IMAGE_REPO}/gpg-vault
GPG_IMAGE_TAG  := pk
RUNNER_IMAGE_NAME := ${IMAGE_REPO}/node
RUNNER_IMAGE_TAG  := bookworm
AUTH_PROXY_IMAGE_NAME := ${IMAGE_REPO}/auth-proxy
AUTH_PROXY_IMAGE_TAG  := latest
CONTAINER_PROXY_IMAGE_NAME := ${IMAGE_REPO}/container-socket-proxy
CONTAINER_PROXY_IMAGE_TAG  := latest
CADDY_IMAGE_NAME := ${IMAGE_REPO}/caddy
CADDY_IMAGE_TAG  := latest
DNSMASQ_IMAGE_NAME := ${IMAGE_REPO}/dnsmasq
DNSMASQ_IMAGE_TAG  := latest
ACNG_IMAGE_NAME := ${IMAGE_REPO}/apt-cacher-ng
ACNG_IMAGE_TAG  := latest
GO_RUNNER_IMAGE_NAME := ${IMAGE_REPO}/go
GO_RUNNER_IMAGE_TAG  := bookworm
USER_SHELL ?= /bin/zsh
BUILD_OPTIONS :=
EXTRA_PKGS :=
CMD := $(shell which podman || which docker)

install:
	./scripts/install-command.sh

image_auth_proxy : IMAGE_NAME = ${AUTH_PROXY_IMAGE_NAME}
image_auth_proxy : IMAGE_TAG = ${AUTH_PROXY_IMAGE_TAG}
image_auth_proxy:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './imags/git-auth-proxy/Dockerfile' \
		./imags/git-auth-proxy

image_container_proxy : IMAGE_NAME = ${CONTAINER_PROXY_IMAGE_NAME}
image_container_proxy : IMAGE_TAG = ${CONTAINER_PROXY_IMAGE_TAG}
image_container_proxy:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './imags/container-socket-proxy/Dockerfile' \
		./imags/container-socket-proxy

image_caddy : IMAGE_NAME = ${CADDY_IMAGE_NAME}
image_caddy : IMAGE_TAG = ${CADDY_IMAGE_TAG}
image_caddy:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './imags/caddy/Containerfile' \
		./imags/caddy

image_dnsmasq: IMAGE_NAME = ${DNSMASQ_IMAGE_NAME}
image_dnsmasq: IMAGE_TAG = ${DNSMASQ_IMAGE_TAG}
image_dnsmasq:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './imags/dnsmasq/Containerfile' \
		./imags/dnsmasq

image_gpg_pk : IMAGE_NAME = ${GPG_IMAGE_NAME}
image_gpg_pk : IMAGE_TAG = ${GPG_IMAGE_TAG}
image_gpg_pk:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-t "${IMAGE_NAME}:latest" \
		-f './imags/gpg-vault-pk/Containerfile' \
		.
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}-debian" \
		-f './imags/gpg-vault-pk/Containerfile.debian' \
		.
image_acng: IMAGE_NAME = ${ACNG_IMAGE_NAME}
image_acng: IMAGE_TAG = ${ACNG_IMAGE_TAG}
image_acng:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './imags/apt-cacher-ng/Containerfile' \
		./imags/apt-cacher-ng

image_dev_shell : image_nvim
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "BASE_IMAGE=localhost/l7/nvim:podman-remote" \
		--build-arg "EXTRA_PKGS=${EXTRA_PKGS}" \
		--build-arg "SHELL=${USER_SHELL}" \
		-t "${IMAGE_REPO}/dev-shell:latest" \
		-t "${IMAGE_REPO}/dev-shell:alpine" \
		-t "${IMAGE_REPO}/dev-shell:nvim" \
		-f './imags/dev-shell/Containerfile' \
		.

image_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
image_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
image_nvim : submodules images_deps
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "EXTRA_PKGS=${EXTRA_PKGS}" \
		--build-arg "SHELL=${USER_SHELL}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './imags/nvim/Containerfile' \
		.

image_nvim_test : IMAGE_NAME = ${NVIM_IMAGE_NAME}
image_nvim_test : IMAGE_TAG = ${NVIM_IMAGE_TAG}
image_nvim_test : image_nvim image_bin_ht
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}-ht:${IMAGE_TAG}" \
		-f test/lsp-js/Containerfile \
		.

image_podman_remote : submodules image_alpine
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_REPO}/podman-remote:latest" \
		-t "${IMAGE_REPO}/podman-remote:alpine" \
		-f './imags/podman-remote/Containerfile' \
		./imags/podman-remote

image_alpine : submodules image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "ALPINE_VERSION=3.20" \
		--build-arg "EXTRA_PKGS=" \
		--build-arg "SHELL=/bin/bash" \
		-t "${IMAGE_REPO}/alpine:3.20" \
		-f './imags/alpine/Containerfile' \
		.

image_bin_ht :
	${CMD} buildx build \
		-t ${IMAGE_REPO}-test/ht:0.2.0 \
		-f test/utils/ht/Containerfile

### GOLANG RUNNERS
image_runner_go_1.20 : IMAGE_NAME = ${GO_RUNNER_IMAGE_NAME}
image_runner_go_1.20 : IMAGE_TAG = ${GO_RUNNER_IMAGE_TAG}
image_runner_go_1.20: submodules
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "GO_VERSION=1.20" \
		-t "${IMAGE_NAME}:1.20-${IMAGE_TAG}" \
		-f './imags/go-runner/Containerfile' \

image_runner_go_1.21 : IMAGE_NAME = ${GO_RUNNER_IMAGE_NAME}
image_runner_go_1.21 : IMAGE_TAG = ${GO_RUNNER_IMAGE_TAG}
image_runner_go_1.21: submodules
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "GO_VERSION=1.21" \
		-t "${IMAGE_NAME}:1.21-${IMAGE_TAG}" \
		-f './imags/go-runner/Containerfile' \

image_runner_go_1.22 : IMAGE_NAME = ${GO_RUNNER_IMAGE_NAME}
image_runner_go_1.22 : IMAGE_TAG = ${GO_RUNNER_IMAGE_TAG}
image_runner_go_1.22: submodules
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "GO_VERSION=1.22" \
		-t "${IMAGE_NAME}:1.22-${IMAGE_TAG}" \
		-f './imags/go-runner/Containerfile' \

image_runner_go: image_runner_go_1.22
	${CMD tag \
		"${IMAGE_NAME}:1.22-${IMAGE_TAG} \
	    "${IMAGE_NAME}:${IMAGE_TAG}"


### NODE RUNNERS

image_runner_node_18 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_18 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_18: submodules #image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "NODE_VERSION=18" \
		--build-arg "NODE_OPTIONS='--trace-warnings'" \
		-t "${IMAGE_NAME}:18-${IMAGE_TAG}" \
		-f './imags/node-runner/Containerfile' \
		.
image_runner_node_20 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_20 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_20: submodules #image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "NODE_VERSION=20" \
		-t "${IMAGE_NAME}:20-${IMAGE_TAG}" \
		-t "${IMAGE_NAME}:latest" \
		-f './imags/node-runner/Containerfile' \
		.
image_runner_node_22 : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_22 : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_22: submodules #image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "NODE_VERSION=22" \
		-t "${IMAGE_NAME}:22-${IMAGE_TAG}" \
		-f './imags/node-runner/Containerfile' \
		.

# with CocoaPods for iOS React Native dev
image_runner_node_ios : IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_runner_node_ios : IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_runner_node_ios: submodules image_runner_node
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "NODE_VERSION=20" \
		-t "${IMAGE_NAME}:ios-${IMAGE_TAG}" \
		-f './imags/cocoapods-runner/Containerfile' \
		-f './imags/cocoapods-runner/Containerfile' \
		./imags/cocoapods-runner

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

# tsserver typescript-language-server
image_lsp_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_lsp_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_lsp_node: image_runner_node_20
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "NODE_VERSION=20" \
		-t "${IMAGE_NAME}:lsp-${IMAGE_TAG}" \
		-f './imags/node-runner/Containerfile.lsp' \
		.
#### Tests

test_compose_run: images_deps
	podman compose run --build --rm \
		--entrypoint /bin/sh -e DEBUG=1 dev-shell -c 'id' | grep -F --quiet 'uid=1000(user) gid=1000(userz) groups=1000(userz)' && echo pass

test_auth_proxy: IMAGE_NAME = ${AUTH_PROXY_IMAGE_NAME}
test_auth_proxy: IMAGE_TAG = ${AUTH_PROXY_IMAGE_TAG}
test_auth_proxy: # image_auth_proxy
	${CMD} run --rm \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		--help

test_container_proxy: IMAGE_NAME = ${CONTAINER_PROXY_IMAGE_NAME}
test_container_proxy: IMAGE_TAG = ${CONTAINER_PROXY_IMAGE_TAG}
test_container_proxy: # image_container_proxy
	${CMD} run --rm \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		-f /usr/local/etc/haproxy/haproxy.cfg \
		-c

test_caddy: IMAGE_NAME = ${CADDY_IMAGE_NAME}
test_caddy: IMAGE_TAG = ${CADDY_IMAGE_TAG}
test_caddy: # image_caddy
	${CMD} run --rm \
		-e GITHUB_PROXY_HOST=bar \
		-e GITHUB_PROXY_PORT=456 \
		-e PKG_PROXY_HOST=foo \
		-e PKG_PROXY_PORT=1234 \
		-e NPMPKG_REGISTRY_HOST=foo \
		-e NPMPKG_REGISTRY_PORT=1234 \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		caddy validate --config /etc/caddy/default.yml  --adapter yaml
	# simply test that expected hostport placeholders appear in config output
	# does not actually test the config consistency
	${CMD} run --rm \
		-e GITHUB_PROXY_HOST=bar \
		-e GITHUB_PROXY_PORT=456 \
		-e PKG_PROXY_HOST=foo \
		-e PKG_PROXY_PORT=1234 \
		-e NPMPKG_REGISTRY_HOST=foo \
		-e NPMPKG_REGISTRY_PORT=1234 \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		caddy adapt --config /etc/caddy/default.yml  --adapter yaml \
			| jq -r '.apps|map(select(.servers))|map(.servers|map(.routes|map(.handle|map(.upstreams|select(.)|map(.dial)))))|flatten|.[]' \
			| (( $$(grep -E "^{env.PKG_PROXY_HOST}:{env.PKG_PROXY_PORT}$$|^{env.GITHUB_PROXY_HOST}:{env.GITHUB_PROXY_PORT}$$" | sort | uniq | wc -l) == 2 ))

test_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
test_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
test_nvim: # image_nvim
	${CMD} run --rm \
		--entrypoint sh \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		-c 'nvim --version'

test_extra_nvim: test_devenv_dir_owner

test_dnsmasq: IMAGE_NAME = ${DNSMASQ_IMAGE_NAME}
test_dnsmasq: IMAGE_TAG = ${DNSMASQ_IMAGE_TAG}
test_dnsmasq: # image_dnsmasq
	${CMD} run --rm \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		dnsmasq --version

test_acng: IMAGE_NAME = ${ACNG_IMAGE_NAME}
test_acng: IMAGE_TAG = ${ACNG_IMAGE_TAG}
test_acng: # image_acng
	${CMD} run --rm \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		apt-cacher-ng -h

test_gpg_pk: IMAGE_NAME = ${GPG_IMAGE_NAME}
test_gpg_pk: IMAGE_TAG = ${GPG_IMAGE_TAG}
test_gpg_pk: # image_gpg_pk
	${CMD} run --rm \
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		gpg --version

test_runner_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
test_runner_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
test_runner_node: # image_runner_node
	${CMD} run --rm \
		"${IMAGE_NAME}:20-${IMAGE_TAG}" \
		-c 'node --version'

test_lsp_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
test_lsp_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
test_lsp_node: # image_lsp_node
	${CMD} run --rm \
		"${IMAGE_NAME}:lsp-${IMAGE_TAG}" \
		--version


# inspect jobs here just for ci, not really useful otherwise

inspect_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
inspect_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
inspect_nvim: # image_nvim
	${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_auth_proxy: IMAGE_NAME = ${AUTH_PROXY_IMAGE_NAME}
inspect_auth_proxy: IMAGE_TAG = ${AUTH_PROXY_IMAGE_TAG}
inspect_auth_proxy: # image_auth_proxy
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_container_proxy: IMAGE_NAME = ${CONTAINER_PROXY_IMAGE_NAME}
inspect_container_proxy: IMAGE_TAG = ${CONTAINER_PROXY_IMAGE_TAG}
inspect_container_proxy: # image_container_proxy
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_gpg_pk: IMAGE_NAME = ${GPG_IMAGE_NAME}
inspect_gpg_pk: IMAGE_TAG = ${GPG_IMAGE_TAG}
inspect_gpg_pk: # image_gpg_pk
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_caddy: IMAGE_NAME = ${CADDY_IMAGE_NAME}
inspect_caddy: IMAGE_TAG = ${CADDY_IMAGE_TAG}
inspect_caddy: # image_caddy
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_dnsmasq: IMAGE_NAME = ${DNSMASQ_IMAGE_NAME}
inspect_dnsmasq: IMAGE_TAG = ${DNSMASQ_IMAGE_TAG}
inspect_dnsmasq: # image_dnsmasq
	${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_acng: IMAGE_NAME = ${ACNG_IMAGE_NAME}
inspect_acng: IMAGE_TAG = ${ACNG_IMAGE_TAG}
inspect_acng: # image_acng
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"

inspect_runner_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
inspect_runner_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
inspect_runner_node: # image_runner_node
	@${CMD} inspect \
		"${IMAGE_NAME}:${IMAGE_TAG}"


# save jobs - it's really about time to template this makefile
export_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
export_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
export_nvim: # image_nvim
	@${CMD} save \
		"${IMAGE_NAME}:${IMAGE_TAG}"

export_auth_proxy: IMAGE_NAME = ${AUTH_PROXY_IMAGE_NAME}
export_auth_proxy: IMAGE_TAG = ${AUTH_PROXY_IMAGE_TAG}
export_auth_proxy: # image_auth_proxy
	@@${CMD} save \
		"${IMAGE_NAME}:${IMAGE_TAG}"

export_container_proxy: IMAGE_NAME = ${CONTAINER_PROXY_IMAGE_NAME}
export_container_proxy: IMAGE_TAG = ${CONTAINER_PROXY_IMAGE_TAG}
export_container_proxy: # image_container_proxy
	@@${CMD} save \
		"${IMAGE_NAME}:${IMAGE_TAG}"

export_gpg_pk: IMAGE_NAME = ${GPG_IMAGE_NAME}
export_gpg_pk: IMAGE_TAG = ${GPG_IMAGE_TAG}
export_gpg_pk: # image_gpg_pk
	@@${CMD} save \
		"${IMAGE_NAME}:${IMAGE_TAG}"

export_caddy: IMAGE_NAME = ${CADDY_IMAGE_NAME}
export_caddy: IMAGE_TAG = ${CADDY_IMAGE_TAG}
export_caddy: # image_caddy
	@@${CMD} save \
		"${IMAGE_NAME}:${IMAGE_TAG}"

export_dnsmasq: IMAGE_NAME = ${DNSMASQ_IMAGE_NAME}
export_dnsmasq: IMAGE_TAG = ${DNSMASQ_IMAGE_TAG}
export_dnsmasq: # image_dnsmasq
	@${CMD} save \
		"${IMAGE_NAME}:${IMAGE_TAG}"

export_runner_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
export_runner_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
export_runner_node: # image_runner_node
	@@${CMD} save \
		"${IMAGE_NAME}:${IMAGE_TAG}"

image_tor:
	podman compose build tor

image_firefox: images_deps_firefox
	podman compose build firefox

image_vnc: images_deps_vnc
	podman compose build vnc

image_xterm: images_deps_xterm
	podman compose build xterm

####

submodules:
	@git submodule update --checkout --init --recursive --rebase

image_docker_compose: submodules
	pushd imags/docker-compose; \
	DOCKER_HOST="$${CONTAINER_HOST:-unix://$${XDG_RUNTIME_DIR}/podman/podman.sock}" docker buildx bake --progress=plain --load image; \
	popd

images_deps: submodules image_docker_compose
	BUILDCOMPOSEFILE=./compose/base-images.compose.yml ./contrib/l7-scripts/bin/compose-build-dependencies dev-shell

images_deps_firefox: submodules
	COMPOSEFILE=./compose/base-images.compose.yml BUILDCOMPOSEFILE=./compose/base-images.compose.yml ./contrib/l7-scripts/bin/compose-build-dependencies firefox

images_deps_vnc: images_deps image_xterm
	COMPOSEFILE=./compose/vnc.compose.yml BUILDCOMPOSEFILE=./compose/base-images.compose.yml ./contrib/l7-scripts/bin/compose-build-dependencies vnc

images_deps_xterm: images_deps
	BUILDCOMPOSEFILE=./compose/base-images.compose.yml ./contrib/l7-scripts/bin/compose-build-dependencies xterm

images: images_deps image_runner_node image_dnsmasq image_gpg_pk image_dev_shell image_acng image_auth_proxy image_container_proxy image_lsp_node

images_gui: images image_xterm image_firefox image_vnc

images_test: images image_nvim_test

test: test_nvim test_runner_node test_gpg_pk

test_e2e_curl:
	set -e; \
	./test/proxy/test-proxy-curl.sh

test_e2e_ghauth:
	set -e; \
	NAME=l7ide-test-runner-ghauth ./devenv.sh gh auth status
	NAME=l7ide-test-runner-ghauth ./devenv.sh gh auth status

test_e2e_node_corepack: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
test_e2e_node_corepack: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
test_e2e_node_corepack: # image_nvim
	set -e; \
	./test/runner-node/test-corepack-pms.sh

test_e2e_node_majors: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
test_e2e_node_majors: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
test_e2e_node_majors: # image_nvim
	set -e; \
	./test/runner-node/test-node-majors.sh

test_e2e_cocoapods_pod:
	set -e; \
	./test/runner-cocoapods/test-ruby-bundler.sh

test_e2e_lsp_typescript : IMAGE_NAME = ${NVIM_IMAGE_NAME}
test_e2e_lsp_typescript : IMAGE_TAG = ${NVIM_IMAGE_TAG}
test_e2e_lsp_typescript : image_nvim_test test_lsp_node
	set -e; \
	IMAGE=${IMAGE_NAME}-ht:${IMAGE_TAG} \
		  NAME=l7ide-test-runner-lsp \
		  SRC_DIR=$$(pwd)/test/lsp-js \
		  SRC_DIR_OPTS=:z,U \
		  ./devenv.sh /bin/bash -l -Ec ./ht-test-1-1.sh

test_devenv_dir_owner:
	set -e; \
	export NAME=l7ide-test-runner-de; \
	export SRC_DIR=$$(mktemp -d --tmpdir "l7test.XXXX"); \
	for p in \
		"/home/user" \
		"/home/user/.config" \
		"$${SRC_DIR}" \
	; do \
		podman compose up -d; \
		owner=$$(./devenv.sh stat --format '%u:%g' "$${p}"); \
		if [[ "$${owner}" != "1000:1000" ]]; then \
			echo "Invalid ownership of $${p}: $${HOME_OWNER}"; \
			export TESTFAIL=1; \
		fi; \
	done; \
	rm -r "$${SRC_DIR}"; \
	if [[ -n "${TESTFAIL}" ]]; then \
		exit 4; \
	fi; \
	echo "perms test pass";
