#!/bin/bash

# Start apache
/usr/sbin/apache2 -D FOREGROUND
cat /var/log/apache2/error.log
