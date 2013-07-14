#!/bin/bash

yum install -y httpd mysql

cat << EOF > /var/www/html/index.html
<h1>It works!</h1>
EOF
