#!/bin/sh
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
    | (if has("field") then "-field=\(.field)" elif has("format") then "-format "+.format else "" end) as $option
    | ("| \($role) | \($var) | \($option) | \(.path) |")
  ' -r