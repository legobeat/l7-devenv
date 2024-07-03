SHELL := /bin/bash
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
CONTAINER_PROXY_IMAGE_NAME := localhost/l7/container-socket-proxy
CONTAINER_PROXY_IMAGE_TAG  := latest
CADDY_IMAGE_NAME := localhost/l7/caddy
CADDY_IMAGE_TAG  := latest
DNSMASQ_IMAGE_NAME := localhost/l7/dnsmasq
DNSMASQ_IMAGE_TAG  := latest
ACNG_IMAGE_NAME := localhost/l7/apt-cacher-ng
ACNG_IMAGE_TAG  := latest
GO_RUNNER_IMAGE_NAME := localhost/l7/go
GO_RUNNER_IMAGE_TAG  := bookworm
USER_SHELL ?= /usr/bin/zsh
BUILD_OPTIONS :=
EXTRA_PKGS := zsh podman-remote
CMD := $(shell which podman || which docker)

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

image_container_proxy : IMAGE_NAME = ${CONTAINER_PROXY_IMAGE_NAME}
image_container_proxy : IMAGE_TAG = ${CONTAINER_PROXY_IMAGE_TAG}
image_container_proxy:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './sidecars/container-socket-proxy/Dockerfile' \
		./sidecars/container-socket-proxy

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
		-t "${IMAGE_NAME}:latest" \
		-f './sidecars/gpg-vault-pk/Containerfile' \
		.
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}-debian" \
		-f './sidecars/gpg-vault-pk/Containerfile.debian' \
		.
image_acng: IMAGE_NAME = ${ACNG_IMAGE_NAME}
image_acng: IMAGE_TAG = ${ACNG_IMAGE_TAG}
image_acng:
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './sidecars/apt-cacher-ng/Containerfile' \
		./sidecars/apt-cacher-ng

image_nvim : IMAGE_NAME = ${NVIM_IMAGE_NAME}
image_nvim : IMAGE_TAG = ${NVIM_IMAGE_TAG}
image_nvim : submodules image_caddy
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "EXTRA_PKGS=${EXTRA_PKGS}" \
		--build-arg "SHELL=${USER_SHELL}" \
		-t "${IMAGE_NAME}:${IMAGE_TAG}" \
		-f './Containerfile' \
		.

image_nvim_test : IMAGE_NAME = ${NVIM_IMAGE_NAME}
image_nvim_test : IMAGE_TAG = ${NVIM_IMAGE_TAG}
image_nvim_test : image_nvim image_bin_ht
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		-t "${IMAGE_NAME}-ht:${IMAGE_TAG}" \
		-f test/lsp-js/Containerfile \
		.
image_bin_ht :
	${CMD} buildx build \
		-t localhost/l7-test/ht:0.2.0 \
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
		--build-arg "NODE_VERSION=22" \
		-t "${IMAGE_NAME}:22-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile' \
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

# tsserver typescript-language-server
image_lsp_node: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
image_lsp_node: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
image_lsp_node: image_runner_node_20
	${CMD} buildx build \
		${BUILD_OPTIONS} \
		--build-arg "SHELL=${USER_SHELL}" \
		--build-arg "NODE_VERSION=20" \
		-t "${IMAGE_NAME}:lsp-${IMAGE_TAG}" \
		-f './sidecars/node-runner/Containerfile.lsp' \
		.
#### Tests

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
		"${IMAGE_NAME}:${IMAGE_TAG}" \
		caddy validate --config /etc/caddy/default.yml  --adapter yaml
	# simply test that expected hostport placeholders appear in config output
	# does not actually test the config consistency
	${CMD} run --rm \
		-e GITHUB_PROXY_HOST=bar \
		-e GITHUB_PROXY_PORT=456 \
		-e PKG_PROXY_HOST=foo \
		-e PKG_PROXY_PORT=1234 \
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

####

submodules:
	@git submodule update --checkout --init --recursive --rebase

images: image_caddy image_dnsmasq image_nvim image_runner_node image_gpg_pk image_acng image_auth_proxy image_container_proxy image_lsp_node

images_test: images image_nvim_test

test: test_nvim test_runner_node test_gpg_pk

test_e2e_curl:
	set -e
	for url in \
		"https://google.com/" \
		"https://google.com" \
		"https://github.com/" \
		"https://github.com" \
		"https://github.com/lspcontainers/lspcontainers.nvim" \
		"https://github.com/actions/example-services/pulls" \
		"https://codeload.github.com/legobeat/mermaid-cli/tar.gz/02153e234a876c95b44e1af84d02bca65681f6d1" \
		"https://registry.npmjs.org/xtend/" \
		"https://registry.npmjs.org/xtend" \
		"https://registry.yarnpkg.com/xtend/" \
		"https://registry.yarnpkg.com/xtend" \
		"https://registry.npmjs.org/npm/9.9.3" \
		"https://registry.npmjs.org/xtend/-/xtend-2.0.4.tgz" \
		"https://registry.yarnpkg.com/xtend/-/xtend-2.0.4.tgz" \
		"https://deb.debian.org/debian/dists/bookworm/InRelease" \
		"http://deb.debian.org/debian/dists/bookworm/InRelease" \
		"http://product-details.mozilla.org/1.0/firefox_versions.json" \
		"https://product-details.mozilla.org/1.0/firefox_versions.json" \
		"http://archive.ubuntu.com/ubuntu/dists/noble/InRelease" \
		"http://product-details.mozilla.org/1.0/firefox_versions.json" \
		"https://product-details.mozilla.org/1.0/firefox_versions.json" \
	; do \
		result=$$(export NAME=l7ide-test-runner; ./devenv.sh \
			curl -f -sSL --tlsv1.2 "$${url}" -o/dev/null \
			-w '%{exitcode}:%{response_code}:%{ssl_verify_result}___%{certs}' \
			| head -n4 \
		); \
		echo "$$result" | grep -Ez --quiet "^0:200:0___(.*Issuer:.*Caddy.*)?\s*\$$" \
			&& echo "pass $$url" \
			|| echo "fail $$url $$(echo "$$result" | head -n3)"; \
		sleep 0.1; \
	done

test_e2e_ghauth:
	set -e
	NAME=l7ide-test-runner-ghauth ./devenv.sh gh auth status
	NAME=l7ide-test-runner-ghauth ./devenv.sh gh auth status

test_e2e_node_corepack: IMAGE_NAME = ${RUNNER_IMAGE_NAME}
test_e2e_node_corepack: IMAGE_TAG = ${RUNNER_IMAGE_TAG}
test_e2e_node_corepack: # image_nvim
	set -e
	./test/runner-node/test-corepack-pms.sh

test_e2e_lsp_typescript : IMAGE_NAME = ${NVIM_IMAGE_NAME}
test_e2e_lsp_typescript : IMAGE_TAG = ${NVIM_IMAGE_TAG}
test_e2e_lsp_typescript : image_nvim_test test_lsp_node
	set -e
	IMAGE=${IMAGE_NAME}-ht:${IMAGE_TAG} \
		  NAME=l7ide-test-runner-lsp \
		  SRC_DIR=$$(pwd)/test/lsp-js \
		  SRC_DIR_OPTS=:z,U \
		  ./devenv.sh /bin/bash -l -Ec ./ht-test-1-1.sh

test_devenv_dir_owner:
	@export NAME=l7ide-test-runner-de; \
	 export SRC_DIR=$$(mktemp -d --tmpdir "l7test.XXXX"); \
	for p in \
		"/home/user" \
		"/home/user/.config" \
		"$${SRC_DIR}" \
	; do \
		owner=$$(./devenv.sh stat --format '%u:%g' "$${p}"); \
		if [[ "$${owner}" != "1000:1000" ]]; then \
			echo "Invalid ownership of $${p}: $${HOME_OWNER}"; \
			export TESTFAIL=1; \
		fi; \
	done; \
	rm -r "$${SRC_DIR}"; \
	if [[ -n "${TESTFAIL}" ]]; then \
		echo 4; \
	fi; \
	echo "perms test pass";
