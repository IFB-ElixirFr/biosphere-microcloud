#!/bin/sh -xe

# Wait for the MySQL backend to be ready
ss-display "Waiting for MySQL backend to be ready"

# Given right access to phpMyAdmin 
chmod 755 /usr/share/phpMyAdmin/
chmod 644 /usr/share/phpMyAdmin/index.php
chmod 644 /etc/phpMyAdmin/config.inc.php

# Start Apache
systemctl start httpd

# Add entry points (HTTP and HTTPS)
old_url_service=$(ss-get url.service)
URL=$(ss-get hostname)
new_url_service=${old_url_service},http://${URL},https://${URL}
ss-set url.service ${new_url_service}

# We are ready
ss-set frontendReady true
ss-display "Frontend ready"

