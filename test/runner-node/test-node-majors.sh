#!/bin/bash
# test shims for major nodejs versions
export L7_SRC_DIR=$(pwd)
for nv in 18 20 22; do
  version=$(NAME="l7ide-test-runner-nv" ./devenv.sh node-${nv} --version)
  # compare if major version is same as expected
  if [[ "$(echo "${version}" | grep -o '[0-9]*' | head -n1)" != "${nv}" ]]; then
    echo "FAIL: node-${nv} is ${version}" >&2
    export TESTFAIL=1
    if [[ -z "${version}" ]]; then
      echo "(Try 'make image_runner_node_${nv}')"
    fi
    continue
  fi
  echo "PASS: node-${nv} is ${version}" >&2
done
if [[ -n "${TESTFAIL}" ]]; then
  echo "(Try 'make image_runner_node_all')"
  exit 1
fi

