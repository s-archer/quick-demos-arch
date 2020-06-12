#!/bin/bash

TEMPFILE=./vault-init-${RANDOM}.tmp

if [ ! -f $(which jq) ]; then
 >&2 echo "jq not found."
 exit 1
fi

if [ -z $1 ]; then
  if [ -z ${VAULT_ADDR} ]; then
    >&2 echo "Vault address not found. Please specify as paramter or set VAULT_ADDR environment variable."
    exit 1
  fi
else
  export VAULT_ADDR=$1
fi

BOOTSTRAP=$(curl -s -o ${TEMPFILE} -w "%{http_code}" -d '{"secret_shares":1, "secret_threshold":1}' -X PUT ${VAULT_ADDR}/v1/sys/init)
if [ ${BOOTSTRAP} == "200" ]; then
  export VAULT_TOKEN=$(cat ${TEMPFILE} | jq -r .root_token)
  echo -n ${VAULT_TOKEN}>vault.token
  export UNSEAL_KEY=$(cat ${TEMPFILE} | jq -r '.keys[0]')
  echo -n ${UNSEAL_KEY}>vault.key
  rm -f ${TEMPFILE}
  exit 0
elif [ ${BOOTSTRAP} == "400" ]; then
  rm -f ${TEMPFILE}
  >&2 echo "Vault already initialized."
  exit 1
fi