#!/bin/bash
if [ "$2" == "" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("export VAULT_TOKEN=\"$(vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=${ID_TOKEN_GITLAB})\"", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "export " + $var + "=\"$(vault kv get "+ if has("mount") then "-mount=\(.mount) " else "" end + if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +")\""),
      "unset VAULT_TOKEN")
  ' -r
elif [ "$2" == "--debug" ] || [ "$2" == "-d" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[]
    | .secrets[]
    | ("vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=${ID_TOKEN_GITLAB} >.vault && export VAULT_TOKEN=\"$(cat .vault)\" && rm .vault || return $?",
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value
        | "vault kv get "+ if has("mount") then "-mount=\(.mount) " else "" end + if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +" > .vault && echo && export " + $var + "=\"$(cat .vault)\" && rm .vault || return $?"),
      "unset VAULT_TOKEN")
  ' -r
elif [ "$2" == "--test" ] || [ "$2" == "-t" ]; then
cat $1 |\
  jc --yaml |\
  jq '
    .[] 
    | .secrets[] 
    | ("vault write -field=token auth/jwt/login role=\(.VAULT_AUTH_ROLE) jwt=${ID_TOKEN_GITLAB} >.vault && export VAULT_TOKEN=\"$(cat .vault)\" && rm .vault", 
      (to_entries | map(select(.key != "VAULT_AUTH_ROLE")) | .[] | .key as $var | .value 
        | "vault kv get "+ if has("mount") then "-mount=\(.mount) " else "" end + if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end + .path +" > /dev/null"),
      "unset VAULT_TOKEN")
  ' -r
elif [ "$2" == "--markdown" ] || [ "$2" == "-m" ]; then
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
    | (if has("mount") then "-mount=\(.mount) " else "" end + if has("field") then "-field=\(.field) " else "" end + if has("format") then "-format=\(.format) " else "" end) as $option
    | ("| \($role) | \($var) | \($option) | \(.path) |")
  ' -r
fi