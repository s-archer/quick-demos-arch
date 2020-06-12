#!/bin/bash

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

if [[ -f vault.key ]]
then
    export UNSEAL_KEY=$(cat vault.key)
else
  echo "vault.key file does not exist!"
  exit 1
fi

UNSEAL=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -d '{"key":"'${UNSEAL_KEY}'"}' ${VAULT_ADDR}/v1/sys/unseal)
if [ ${UNSEAL} == "200" ]; then
  echo "Vault succesfully unsealed."
  exit 0
fi