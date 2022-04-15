#!/bin/bash
if [ "$2" == "" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .kv_puts[] 
    | ("export VAULT_TOKEN=\"$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT)\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $key | .value.value as $value | .value.path as $path
        | "vault kv put "+ if has("format") then "-format=\(.format) " else "" end + "\($path) \($key)=\"\($value)\""))
  ' -r
elif [ "$2" == "--markdown" ] || [ "$2" == "-m" ]; then
echo "| role | path| key | value | option |"
echo "| --- | --- | --- | --- | --- |"
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
    | .key as $key 
    | .value.value as $value 
    | .value.path as $path
    | (if has("format") then "-format=\(.format) " else "" end) as $option
    | ("| \($role) | \($path) | \($key) | \($value) | \($option) | ")
  ' -r
fi