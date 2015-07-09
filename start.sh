#!/bin/bash

# Start apache
apache2ctl start

tail -f /var/log/apache2/error.log
