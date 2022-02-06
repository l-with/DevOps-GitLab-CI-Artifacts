#!/bin/sh
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("echo vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=\\$CI_JOB_JWT \\>.vault \\&\\& export VAULT_TOKEN=\"\\$(cat .vault) && rm .vault\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] 
        | ("echo vault kv get -field=\(.value.vault | split("@")[0] | split("/")[-1]) \(.value.vault | split("@")[1] + "/" + (split("@")[0] | split("/")[0:-1] | join("/"))) \\>.vault \\&\\& export \(.key)=\"\\$(cat .vault) && rm .vault\"")))
  ' -r