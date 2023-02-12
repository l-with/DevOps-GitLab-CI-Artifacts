#!/bin/bash
if [ "$2" == "" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .kv2_patches
    | .[] 
    | ("export VAULT_TOKEN=\"$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=$CI_JOB_JWT)\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "vault kv patch "+ if has("mount") then "-mount=\(.mount) " else "" end + .path + " " + .field + "=$" + $var),
      "unset VAULT_TOKEN")
  ' -r
elif [ "$2" == "--markdown" ] || [ "$2" == "-m" ]; then
echo "| variable | role | option | path | field |"
echo "| --- | --- | --- | --- | --- |"
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .kv2_patches 
    | .[] 
    | .VAULT_AUTH_ROLE as $role 
    | to_entries 
    | map(select(.key != "VAULT_AUTH_ROLE")) 
    | .[] 
    | .key as $var 
    | .value 
    | .path as $path
    | (if has("mount") then "-mount=\(.mount) " else "" end + if has("format") then "-format=\(.format) " else "" end) as $option
    | ("| \($var) | \($role) | \($option) | \(.path) | \(.field) |")
  ' -r
fi
