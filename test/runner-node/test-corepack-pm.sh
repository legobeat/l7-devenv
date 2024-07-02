#!/bin/bash

# Test that package manager versions gets used according to package.json packageManager field
set -e
cd "${1}"
TEST_PM=${2}

pmversion="$(${TEST_PM} --version)"
pmversion_expected="$(jq -r .packageManager package.json)"

if [[ ! "${TEST_PM}@${pmversion}" == "${pmversion_expected}" ]]; then
  echo "${TEST_PM}@${pmversion} !=  ${pmversion_expected} : fail"
  exit 3
fi

echo "${TEST_PM}@${pmversion}" == "${pmversion_expected} : pass"
