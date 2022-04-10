#!/bin/sh
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("export VAULT_TOKEN=\"$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT)\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "export " + $var + "=\"$(vault kv get "+if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +")\""))
  ' -r