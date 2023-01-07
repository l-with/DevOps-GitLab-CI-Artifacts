#!/bin/bash
if [ "$2" == "" ]; then
echo "vault auth role missng"
else
VAULT_AUTH_ROLE=$2
export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=$VAULT_AUTH_ROLE jwt=$CI_JOB_JWT)"
fi