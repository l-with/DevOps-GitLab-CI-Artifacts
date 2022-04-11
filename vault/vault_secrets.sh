#!/bin/sh
if [ X"$2" = X"_" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("export VAULT_TOKEN=\"$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT)\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "export " + $var + "=\"$(vault kv get "+if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +")\""))
  ' -r
elif [ X"$2" = X"_--debug" ] || [ X"$2" = X"-d" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT >.vault && export VAULT_TOKEN=\"$(cat .vault)\" && rm .vault", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "vault kv get "+if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +" > .vault && echo && export " + $var + "=\"$(cat .vault)\" && rm .vault"))
  ' -r
elif [ X"$2" = X"--test" ] || [ X"$2" = X"-t" ]; then
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
elif [ "X$2" = X"_-markdown" ] || [ X"$2" = X"-m" ]; then
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