#!/bin/bash

wd="$(mktemp -d)"
export SRC_DIR=$wd

#bundler_version=$(NAME="l7ide-test-runner-rbb" ./devenv.sh bundler --version)
#pod_version=$(NAME="l7ide-test-runner-rbb" ./devenv.sh pod --version)

NAME="l7ide-test-runner-rbb" ./devenv.sh bundler --version

# perform shallow clone of React Native project and test `pod install`

git clone --depth=1 --filter=blob:none --sparse https://github.com/MetaMask/metamask-mobile "${wd}"
pushd "${wd}"
git sparse-checkout set --no-cone /package.json /yarn.lock /ios/** /.* /scripts/** /Gemfile* /patches/*
popd



NAME="l7ide-test-runner-rbb" ./devenv.sh pod --version
# TODO: Autodetect and switch runner image if in mobile env
#mm_mobile_setup_result=$(NAME="l7ide-test-runner-rbb" NODE_RUNNER_IMAGE="localhost/l7/node:ios-bookworm" ./devenv.sh yarn setup --build-ios)
mm_mobile_setup_result=$(NAME="l7ide-test-runner-rbb" NODE_RUNNER_IMAGE="localhost/l7/node:ios-bookworm" ./devenv.sh bash -c "yarn setup:node && pod install --project-directory=ios")

echo $result
