#!/bin/bash
if [ "$1" == "" ]; then
echo "vault auth role missing"
else
VAULT_AUTH_ROLE=$1
export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=$VAULT_AUTH_ROLE jwt=$CI_JOB_JWT)"
fi