#!/bin/bash

export _README_MD=$1
export README_MD=${_README_MD:-README.md}

CHANGED=0

if [ -n "$(tail -c 1 $README_MD)" ]; then echo >> $README_MD; fi

grep '<!-- BEGIN_ENV_DOCS_' $README_MD | sed -r 's/.*BEGIN_ENV_DOCS_//' | cut -d " " -f 1 >.env_docs
echo found the folowing environments in $README_MD: $(cat .env_docs)
while read line
do
    export ENVIRONMENT=$line

    export BEGIN_LINE=$(grep -n -m 1 '<!-- BEGIN_ENV_DOCS_'"$ENVIRONMENT"' -->' $README_MD | cut -d ':' -f 1)
    export END_LINE=$(grep -n -m 1 '<!-- END_ENV_DOCS_'"$ENVIRONMENT"' -->' $README_MD | cut -d ':' -f 1)
    export NUM_LINES=$(cat $README_MD | wc -l)
    let TAIL_LINES=1+NUM_LINES-END_LINE

    echo $ENVIRONMENT $BEGIN_LINE $END_LINE $NUM_LINES $TAIL_LINES

    TEMP_README_MD=$(mktemp -t README_MD.XXXX)
    head --lines=$BEGIN_LINE $README_MD > $TEMP_README_MD

    echo "| variable | value | comment |" >> $TEMP_README_MD
    echo "| --- | --- | --- |" >> $TEMP_README_MD
    echo "var","value"#"comment" |\
        cat - environment/${ENVIRONMENT}.env |\
        tr '=' ',' |\
        sed -E 's/ +# +/#/' |\
        sed -E 's/^([^#]*)$/\1#/' |\
        tr '#' ',' |\
        jc --csv -p |\
        jq '
        .[] | ("| \(.var) | \(.value) | \(.comment) |")
        ' -r >> $TEMP_README_MD

    tail --lines=$TAIL_LINES $README_MD >> $TEMP_README_MD

    diff $TEMP_README_MD ${README_MD} >/dev/null
    if [ $? != 0 ]; then
        echo ${README_MD} changed by environment/${ENVIRONMENT}.env
        CHANGED=1
    fi
    mv $TEMP_README_MD $README_MD
done < .env_docs

rm .env_docs

exit $CHANGED
