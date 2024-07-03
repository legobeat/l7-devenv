#!/bin/bash
set -x
# test auto-version from package.json
for pm in yarn pnpm npm; do
  export TEST_PM=${pm};
  export TEST_DIR=${pm};
  if [[ -n "${DEBUG}" ]]; then
    export RUN_ARGS="${RUN_ARGS} -e DEBUG=${DEBUG}"
  fi
  for pmv in $(find test/runner-node/fixtures/corepack -maxdepth 1 -name "${pm}*") ; do
    NAME=l7ide-test-runner-corepack ./devenv.sh $(pwd)/test/runner-node/test-corepack-pm.sh "${pmv}" "${pm}"
  done
done

# test global shims
for pm in yarn1 yarn3 yarn4 npm7 npm9 npm10 pnpm9; do
  version=$(NAME="l7ide-test-runner-corepack" ./devenv.sh ${pm} --version)
  # compare if major version is same as expected
  if [[ "$(echo "${version}" | grep -o '[0-9]*' | head -n1)" != "$(echo "${pm}" | grep -o '[0-9]*' | head -n1)" ]]; then
    echo "FAIL ${pm} is v${version}" >&2
    export TESTFAIL=1
    continue
  fi
  echo "PASS ${pm} is v${version}" >&2
done
if [[ -n "${TESTFAIL}" ]]; then
  exit 1
fi
