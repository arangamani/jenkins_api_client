#!/bin/bash -x

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update -qq
sudo apt-get install -qq jenkins

# Configure Jenkins
sudo service jenkins stop
sudo cp -f travis/jenkins_config.xml /var/lib/jenkins/config.xml
sudo cp -f travis/hudson.model.UpdateCenter.xml /var/lib/jenkins/hudson.model.UpdateCenter.xml
sudo mkdir -p /var/lib/jenkins/users/testuser
sudo cp -f travis/user_config.xml /var/lib/jenkins/users/testuser/config.xml
sudo service jenkins start
# Jenkins takes a bit to get dressed up and become ready, so be patient...
sleep 60
cat /var/log/jenkins/jenkins.log
echo `sudo service jenkins status`

# Create the credentials file used by functional tests
sudo mkdir ~/.jenkins_api_client
sudo cp -f travis/spec.yml ~/.jenkins_api_client/spec.yml
