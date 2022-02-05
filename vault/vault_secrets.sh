#!/bin/sh
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("echo export VAULT_TOKEN=\"\\$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=\\$CI_JOB_JWT)\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] 
        | ("echo export \(.key)=\"\\$(vault kv get -field=\(.value.vault | split("@")[0] | split("/")[-1]) \(.value.vault | split("@")[1] + "/" + (split("@")[0] | split("/")[0:-1] | join("/"))))\"")))
  ' -r