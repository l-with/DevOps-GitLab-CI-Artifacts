#!/bin/bash
if [ "$2" == "" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .kv_puts[] 
    | ("export VAULT_TOKEN=\"$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT)\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] 
      | .key as $path | (.value | to_entries) as $kvs
        | ("rm -f .kv", 
          ($kvs | .[] | .key as $key | .value as $value | "echo '"'"'\($key)=\($value)'"'"' >>.kv")),
          "jc --kv <.kv >.json",
          "rm .kv",
          "vault kv put \($path) @.json",
          "rm .json"))
  ' -r
elif [ "$2" == "--markdown" ] || [ "$2" == "-m" ]; then
echo "| role | path| key | value |"
echo "| --- | --- | --- | --- |"
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .kv_puts 
    | .[] 
    | .VAULT_AUTH_ROLE as $role 
    | to_entries 
    | map(select(.key != "VAULT_AUTH_ROLE")) 
    | .[] 
    | .key as $path
    | (.value | to_entries) as $kvs
    | ($kvs | .[] | .key as $key | .value as $value
      | ("| \($role) | \($path) | \($key) | \($value) |"))
  ' -r
fi