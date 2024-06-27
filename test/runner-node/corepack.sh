#!/bin/bash
test_corepack_pm_version () {
  cd $1
  echo  "yarn@$$(yarn --version)"  "$$(jq -r .packageManager package.json)"  '  
}

for pm in npm pnpm yarn; do
  find test/runner-node/fixtures/corepack -maxdepth 1 -name "${pm}*" \
      -exec ./devenv.sh \
        'cd {} && \;
done
""
