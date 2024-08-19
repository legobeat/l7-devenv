#!/bin/bash
export NAME=l7ide-test-xterm-vnc
export L7_SRC_DIR=$(mktemp -p "${PWD}" -d)
function cleanup {
  rm -rf  "${L7_SRC_DIR}"
}
trap cleanup EXIT

podman compose up --no-build -d --wait
podman compose up --no-build vnc &
sleep 10
podman compose exec vnc ratpoison -c 'exec xterm "-c \"echo -n hello > /src/hello.txt\""'
sleep 20
result="$(cat "${L7_SRC_DIR}/hello.txt")"
if [[ "${result}" != "hello" ]]; then
  echo "FAIL" >&2
  exit 2
fi
echo "pass"
