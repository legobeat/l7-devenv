#!/bin/bash
for pm in yarn pnpm npm; do
  export TEST_PM=${pm};
  export TEST_DIR=${pm};
  export NAME=l7ide-test-runner;
  if [[ -z "${DEBUG}" ]]; then
    export RUN_ARGS="${RUN_ARGS} -e DEBUG=${DEBUG}"
  fi
  find test/runner-node/fixtures/corepack -maxdepth 1 -name "${pm}*" \
    -exec ./devenv.sh $(pwd)/test/runner-node/test-corepack-pm.sh {} ${pm} \;
done
