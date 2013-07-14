#!/bin/bash

yum install -y httpd mysql

chkfonfig httpd on
service httpd start

cat << EOF > /var/www/html/index.html
<h1>It works!</h1>
EOF
