#!/bin/bash

DL_DIR=data
BASE_URL='http://octayn.net/benches/'
HIST_FILE=history.txt
MEM_FILE=mem.json.gz
TIME_FILE=time.txt
CI_FILE=commit_info.txt

mkdir -p $DL_DIR
cd $DL_DIR

curl -s ${BASE_URL}${HIST_FILE} -o ${HIST_FILE}

# Check for any hashes that haven't been downloaded (i.e. there is no
# directory with the same name)
hashes=$(python <<EOF
import os
history = open('history.txt').read().split()
already = os.listdir('data')
print('\n'.join(sorted(set(history) - set(already))))
EOF
)

for hash in $hashes; do
    (
        echo $hash
        mkdir -p data/$hash
        cd data/$hash
        for f in $MEM_FILE $TIME_FILE $CI_FILE; do
            curl -f -s ${BASE_URL}data/${hash}/$f -o $f
        done

        # sometimes we get a 404 error, so just kill the directory and
        # wait till next time
        if ! (
                gunzip -f $MEM_FILE &&
                python -c 'import sys, json; json.load(sys.stdin)' < ${MEM_FILE%.gz}
                # && [[ -f $TIME_FILE ]] time.txt isn't compulsory
            ); then
            echo $hash failed
            cd ..
            rm -rf $hash
        fi
    ) &
done

wait
