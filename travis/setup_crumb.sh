#!/bin/bash

# Replace jenkins configuration file with crumb enabled
sudo cp -f travis/jenkins_config_with_crumb.xml /var/lib/jenkins/config.xml
# Restart jenkins for the new configuration to take effect
sudo service jenkins restart
# Jenkins takes a bit to get ready - so wait
sleep 60
cat /var/log/jenkins/jenkins.log
echo `sudo service jenkins status`

echo "Crumb is enabled on jenkins"
