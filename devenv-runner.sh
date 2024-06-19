#!/bin/bash

export SSH_SOCKET=''
export IMAGE_NAME='l7/node'
export IMAGE_TAG='20-bookworm'
export RUN_ARGS="-e HOME=/home/node ${RUN_ARGS}"
export NAME=${NAME:-l7-node-20}

$(dirname "$0")/devenv.sh ${@}
