#!/bin/bash

export _README_MD=$1
export README_MD=${_README_MD:-README.md}

export SUB_PIPELINE=$2

CHANGED=0

grep '<!-- BEGIN_VAULT_SECRETS_DOCS_' $README_MD | sed -r 's/.*BEGIN_VAULT_SECRETS_DOCS_//' | cut -d " " -f 1 >.vault_secrets_docs
echo found the folowing secrets environments in $README_MD: $(cat .vault_secrets_docs)
while read line
do
    export ENVIRONMENT_PIPELINE=$line
    IFS='_' read -a PARTS <<<"$ENVIRONMENT_PIPELINE"
    export ENVIRONMENT=${PARTS[0]}
    export PIPELINE=${PARTS[1]}

    if [ $PIPELINE != SUB_PIPELINE ]; then
        continue
    fi
    
    export BEGIN_LINE=$(grep -n -m 1 '<!-- BEGIN_VAULT_SECRETS_DOCS_'"$ENVIRONMENT_PIPELINE"' -->' $README_MD | cut -d ':' -f 1)
    export END_LINE=$(grep -n -m 1 '<!-- END_VAULT_SECRETS_DOCS_'"$ENVIRONMENT_PIPELINE"' -->' $README_MD | cut -d ':' -f 1)
    export NUM_LINES=$(cat $README_MD | wc -l)
    let TAIL_LINES=NUM_LINES-END_LINE+1
    # echo $ENVIRONMENT $BEGIN_LINE $END_LINE $NUM_LINES $TAIL_LINES

    TEMP_README_MD=$(mktemp)
    head --lines=$BEGIN_LINE $README_MD > $TEMP_README_MD
    vault_secrets.sh secrets/$ENVIRONMENT.yml --markdown >> $TEMP_README_MD
    tail --lines=$TAIL_LINES $README_MD >> $TEMP_README_MD

    diff $TEMP_README_MD ${README_MD} >/dev/null
    if [ $? != 0 ]; then
        echo ${README_MD} changed by secrets/$ENVIRONMENT.yml
        CHANGED=1
    fi
    mv $TEMP_README_MD ${README_MD}
done < .vault_secrets_docs

rm .vault_secrets_docs

exit $CHANGED