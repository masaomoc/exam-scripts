#!/bin/bash

set -e
LANG=C

tmpdir=/tmp/$$
mkdir -p ${tmpdir}

trap 'rm -rf ${tmpdir}; echo -n exitting...' EXIT

messageFile=${tmpdir}/message
receiptHandle=${tmpdir}/receiptHandle
region=ap-northeast-1
url=`
    aws sqs list-queues --region ${region} \
        | jq -c '.QueueUrls | .[0]'        \
        | tr -d '"'
`

# loop and display message
while :
do
    aws sqs receive-message \
        --region ${region}  \
        --queue-url ${url} > ${messageFile}

    # retrieve message body and remove escape sequenses
    body=`
        cat $messageFile                   \
            | jq -c '.Messages | .[].Body' \
            | sed -e 's/\\\\//g'
    `

    # write into file not to be escaped
    cat $messageFile                            \
        | jq -c '.Messages | .[].ReceiptHandle' \
        | tr -d '"' > ${receiptHandle}

    if [ -z "${body}" -o "${body}" = null ]; then
        :
    else
        echo $body

        aws sqs delete-message          \
            --region         ${region}  \
            --queue-url      ${url}     \
            --receipt-handle `cat ${receiptHandle}` > /dev/null
    fi
    sleep 30
done
