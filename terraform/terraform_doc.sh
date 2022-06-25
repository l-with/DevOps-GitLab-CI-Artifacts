#!/bin/bash
TF_FOLDER=$(mktemp -d)
echo $TF_FOLDER

for TF_FILE_PATH in $1/*.tf
do
    TF_FILE=$(basename $TF_FILE_PATH)
    hcl2tojson $TF_FILE_PATH $TF_FOLDER/$TF_FILE.json
done

cat $TF_FOLDER/*.json | jq -s -c

# hcl2tojson $1 $TF_FOLDER
echo "| variable | type | description | default |"
echo "| --- | --- | --- | --- |"
cat $TF_FOLDER/*.json |\
  jq -r -s -c '
    [[.[] | .variable | arrays ] | flatten | .[] | to_entries | .[]] 
    | .[] 
    | .key as $var 
    | (.value.type[0] | ltrimstr("${") | rtrimstr("}")) as $type 
    | (.value.description[0] | .+"" | sub("\\n";"<br />";"g")) as $description 
    | (.value.default[0] | if(. == null) then .+"" else . end) as $default 
    | ("| \($var) | \($type) | \($description) | \($default) |")'
