#!/bin/bash

cd /home/ec2-user

yum install -y git jq

git clone https://github.com/masaomoc/exam-scripts.git exam
chown -R ec2-user:ec2-user exam/

echo '*/1 * * * * /bin/bash /home/ec2-user/exam/publish.sh' | crontab -u ec2-user
