#!/bin/sh
echo "| variable | role | path | field |"
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
    | { path: (.vault | split("@")[1] + "/" + (split("@")[0] | split("/")[0:-1] | join("/"))), field: (.vault | split("@")[0] | split("/")[-1]) }  
    | ("| \($var) | \($role) | \(.path) | \(.field) |")
  ' -r