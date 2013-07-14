#!/bin/bash

set -e
LANG=C
cd `dirname $0` || exit 1

trap 'echo exitting...' EXIT

aws=`which aws`
jq=`which jq`

# Instance metadata
metadataUrl="http://169.254.169.254/latest/meta-data/"
instanceId=`curl ${metadataUrl}instance-id 2>/dev/null`

# Cloudwatch/SNS settings
region=ap-northeast-1
namespace=AWS/EC2
metrics=CPUUtilization
statistics='["Minimum","Average","Maximum"]'
period=60
startTime=`date --date '2 minutes ago'`
endTime=`date --date '1 minutes ago'`

dimensionKey=InstanceId
dimensionValue=$instanceId
dimensions="{\"name\":\"${dimensionKey}\",\"value\":\"${dimensionValue}\"}"

topicARN=`${aws} sns list-topics --region ${region} | ${jq} '.[].TopicArn' | tr -d '"'`

# configuration end

# retrieve data from cloudwatch
dataJson=`
    ${aws} cloudwatch get-metric-statistics \
        --region       ${region}            \
        --namespace    ${namespace}         \
        --metric-name  ${metrics}           \
        --statistics   ${statistics}        \
        --period       ${period}            \
        --start-time  "${startTime}"        \
        --end-time    "${endTime}"          \
        --dimensions   ${dimensions}        \
    | ${jq} -c '.Datapoints | .[0]'
`

if [ -z ${dataJson} -o ${dataJson} = null ]; then
    echo 'data does not found' 1>&2 && exit 1
fi

# for testing...

average=`echo ${dataJson} | jq '.Average'`
message="使用率：${average}%"

# publish JSON message
${aws} sns publish           \
    --topic-arn  ${topicARN} \
    --message    ${message} \
    --region     ${region}   > /dev/null
