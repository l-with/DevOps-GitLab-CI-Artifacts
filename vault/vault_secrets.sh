#!/bin/sh
if [ "_$2" == "_" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("export VAULT_TOKEN=\"$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT)\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "export " + $var + "=\"$(vault kv get "+if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +")\""))
  ' -r
elif [ "_$2" == "_--debug" ] || [ "_$2" == "_-d" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT >.vault && export VAULT_TOKEN=\"$(cat .vault)\" && rm .vault", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "vault kv get "+if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +" > .vault && echo && export " + $var + "=\"$(cat .vault)\" && rm .vault"))
  ' -r
elif [ "_$2" == "_--test" ] || [ "_$2" == "_-t" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT >.vault && export VAULT_TOKEN=\"$(cat .vault)\" && rm .vault", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "vault kv get "+if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +" > /dev/null"),
      "unset VAULT_TOKEN")
  ' -r
elif [ "_$2" == "_-markdown" ] || [ "_$2" == "_-m" ]; then
echo "| role | variable | option | path |"
echo "| --- | --- | --- | --- |"
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets 
    | .[] 
    | .VAULT_AUTH_ROLE as $role 
    | to_entries 
    | map(select(.key != "VAULT_AUTH_ROLE")) 
    | .[] 
    | .key as $var 
    | .value 
    | .path as $path
    | (if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end) as $option
    | ("| \($role) | \($var) | \($option) | \(.path) |")
  ' -r
fi