#!/bin/bash

export IMAGE_NAME="${IMAGE_NAME:-l7/node}"
export IMAGE_TAG="${IMAGE_TAG:-20-bookworm}"
export NAME=${NAME:-l7-node-20}
export GPG_PK_VOLUME=''
export SSH_SOCKET=''
export RUN_ARGS="-e HOME=/home/node ${RUN_ARGS}"

$(dirname "$0")/devenv.sh ${@}
