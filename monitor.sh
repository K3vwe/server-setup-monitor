#/bin/bash

# Exit immediately if a command fails
set -e

#Include logs
exec > >(tee -i /var/log/monitor.log)
exec 2>&1

# Load Configuration Variables
source ./config.conf