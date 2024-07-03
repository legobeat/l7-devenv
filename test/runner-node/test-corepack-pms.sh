#!/bin/bash
# test auto-version from package.json
export L7_SRC_DIR=$(pwd)
for pm in yarn pnpm npm; do
  export TEST_PM=${pm};
  export TEST_DIR=${pm};
  if [[ -n "${DEBUG}" ]]; then
    export RUN_ARGS="${RUN_ARGS} -e DEBUG=${DEBUG}"
  fi
  find test/runner-node/fixtures/corepack -maxdepth 1 -name "${pm}*" \
    -exec ./devenv.sh $(pwd)/test/runner-node/test-corepack-pm.sh {} ${pm} \;
done
