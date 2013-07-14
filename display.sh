#!/bin/bash

set -e
LANG=C

tmpdir=/tmp/$$
mkdir -p ${tmpdir}

trap 'rm -rf ${tmpdir}; echo -n exitting...' EXIT

messageFile=${tmpdir}/message
receiptHandle=${tmpdir}/receiptHandle

region=ap-northeast-1
url=`/usr/bin/aws sqs list-queues --region ${region} | /usr/bin/jq -c '.QueueUrls | .[0]' | tr -d '"'`

# loop and display message
while :
do
    /usr/bin/aws sqs receive-message \
        --region ${region}           \
        --queue-url ${url} > ${messageFile}

    # retrieve message body and remove escape sequenses
    body=`cat $messageFile | /usr/bin/jq -c '.Messages | .[].Body' | sed -e 's/\\//g'`

    # write to file not to be escaped
    cat $messageFile | /usr/bin/jq -c '.Messages | .[].ReceiptHandle' | tr -d '"' > ${receiptHandle}

    if [ -z ${body} -o ${body} != null ]; then
        echo $body

        /usr/bin/aws sqs delete-message \
            --region         ${region}  \
            --queue-url      ${url}     \
            --receipt-handle `cat ${receiptHandle}` > /dev/null
    fi

    sleep 30
done
