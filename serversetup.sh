#!/bin/bash

# Exit immediately if a command fails
set -e

#Update and Upgrade existing system services on the server
apt update && apt upgrade -y
echo

#Install Core System Packages and Utilities
echo ">>> Installing System Essentials......."
apt install -y build-essential curl wget git ufw unzip tar openssh-server
echo ">>> Core system package installation successful........" 
echo

#Install Web server software & nodejs runtime framework packages
echo ">>> Installing Web server software & nodejs runtime framework packages......."
apt install -y apache2 nodejs npm
echo ">>> Web Server & Runtime Framework installation successful........" 
echo

#Install Database & Security Packages
echo ">>> Installing Database & Security Packages......."
apt install -y postgresql openssl fail2ban
echo ">>> Database & Security Packages installation successful........" 
echo