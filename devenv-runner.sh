#!/bin/bash

export SSH_SOCKET=''
export IMAGE_NAME='l7-node'
export IMAGE_TAG='20-bookworm'
export RUN_ARGS="--entrypoint /bin/bash -e HOME=/home/node ${RUN_ARGS}"

$(dirname "$0")/devenv.sh ${@}
