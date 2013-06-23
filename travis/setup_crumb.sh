#!/bin/bash

# Replace jenkins configuration file with crumb enabled
sudo cp -f travis/jenkins_config_with_crumb.xml /var/lib/jenkins/config.xml
# Restart jenkins for the new configuration to take effect
sudo service jenkins restart
# Jenkins takes a bit to get ready - so wait
sleep 60
echo `sudo service jenkins status`

echo "Crumbs support is enabled on jenkins"
