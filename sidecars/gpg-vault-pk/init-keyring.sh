#!/bin/sh
[ -n "${DEBUG}" ] && set -x
chmod 0700 /vault/gnupg
GPG_NAME="${GPG_NAME:-$1}"
GPG_EMAIL="${GPG_EMAIL:-$2}"
GPG_ALGO="${GPG_ALGO:-ed25519/cert,sign}"
# skip generating encryption key makes export simpler
# GPG_ALGO="${GPG_ALGO:-'ed25519/cert,sign+cv25519/encr'}"
GPG_EXPIRY="${GPG_EXPIRY:-6m}"

[ -z "${GPG_NAME}" ] && echo 'Missing required GPG_NAME' && exit 1
[ -z "${GPG_EMAIL}" ] && echo 'Missing required GPG_EMAIL' && exit 1

gpg --quick-gen-key \
  "${GPG_NAME} <${GPG_EMAIL}>" \
  "${GPG_ALGO}" \
  "${GPG_COMMENT}" \
  "${GPG_EXPIRY}"

gpg --export -a
