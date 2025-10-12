#!/bin/bash

# Exit immediately if a command fails
set -e

#Include logs
exec > >(tee -i /var/log/setup.log)
exec 2>&1

# Load Configuration Variables
source ../config/config.conf

# Update and Upgrade existing system services on the server
apt update && apt upgrade -y && apt autoremove -y
echo

# Install Core System Packages and Utilities
echo ">>> Installing System Essentials......."
apt install -y build-essential curl wget git ufw unzip tar openssh-server mailutils
echo ">>> Core system package installation successful........" 
echo

# Install Web server software & nodejs runtime framework packages
echo ">>> Installing Web server software & nodejs runtime framework packages......."
apt install -y apache2 nodejs npm
echo ">>> Web Server & Runtime Framework installation successful........" 
echo

# Install Database & Security Packages
echo ">>> Installing Database & Security Packages......."
apt install -y postgresql openssl fail2ban
echo ">>> Database & Security Packages installation successful........" 
echo

# Starting Service Configuration Process
echo ">>> Configure git for user"
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

# Configure Firewall to open ssh http https
echo ">>> Configuring UFW Firewall"
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable
ufw status verbose
echo

# Configure Openssh-server
# Make a copy of /etc/ssh/sshd_config and protect the original settings as reference for reuse
if [ -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.original
    chmod a-w /etc/ssh/sshd_config.original
fi;

# Testing SSH for syntax errors
echo ">>> Testing SSH for syntax errors"
sshd -t -f /etc/ssh/sshd_config
systemctl enable ssh
systemctl start ssh
echo 

# Configure Mailutils
cat >> ~/.mailrc << EOF
# Gmail SMTP settings for alert script
set smtp-use-starttls
set ssl-verify=ignore
set smtp=smtp://smtp.gmail.com:587
set smtp-auth=login
set smtp-auth-user=your_email@gmail.com
set smtp-auth-password=YOUR_APP_PASSWORD
set from="your_email@gmail.com"
EOF 

# Change ownership of ~/.mailrc to the user
chmod 600 ~/.mailrc

# Configure Fail2ban for Intrusion detection
echo ">>> Configure Fail2ban to detect and block intrusion"
# Check if /etc/fail2ban exist, make a copy and protect tge original settings as reference for reuse
if [ -f /etc/fail2ban/jail.conf ]; then
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.original
    chmod a-w /etc/fail2ban/jail.conf.original
fi;
# Create the jail.local with the conf
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
# "ignoreip" can be an IP address, a CIDR mask or a DNS host
ignoreip = 127.0.0.1
bantime = 3600        # Ban for 1 hour
findtime = 600        # Look at failed attempts in last 10 minutes
maxretry = 3          # Max failed attempts before ban
backend = systemd

[sshd]
enabled = true
port    = 22
filter  = sshd
logpath = /var/log/auth.log

[apache-auth]
enabled = true
port    = http,https
filter  = apache-auth
logpath = /var/log/apache2/*error.log
EOF

# Change ownership of /etc/jail2ban/jail.local to root
chown root:root /etc/fail2ban/jail.local
chmod 644 /etc/fail2ban/jail.local


# Enable and start fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

# Show status
fail2ban-client status
echo ">>> Fail2ban installation and configuration complete!"