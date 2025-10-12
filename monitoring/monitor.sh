#!/bin/bash

# Script: Continously monitor a set of log files for specifc error patterns and send alerts via email or slack 
# and store them in an audit log file
# This script uses tail and grep to monitor log files in real-time.
# It checks for specific error patterns defined in the configuration file.
# When a pattern is detected, it logs the event to an audit log file and sends an alert via email or slack.
# The script also includes log rotation to manage the size of the audit log file.
# Configuration options are set in the config.conf file.

# Exit immediately if a command fails
set -e

#Include logs
exec > >(tee -i /var/log/alert.log)
exec 2>&1

# Load Configuration Variables
source ../config/config.conf

# REGEX pattern to search for in log files
REGEX_PATTERN="$(IFS='|'; echo "${ERROR_PATTERNS[*]}")"

# Monitor log files for error patterns and save error lines to audit log
echo ">>> Monitoring log files for error patterns......."
echo "Log Files: ${LOG_FILES[*]}"
echo "Error Patterns: ${ERROR_PATTERNS[*]}"
echo "Audit Log: $AUDIT_LOG"
echo

# function to check and rotate audit log if it exceeds 5MB
# if so create a compressed backup and clear the file
rotate_audit_log () {
    # Check if the audit file exists and check if the audit log size is greater than 5MB,
    if [[ -f "$AUDIT_LOG" && "$(stat -c%s "$AUDIT_LOG")" -ge "$LOG_ROTATION_SIZE" ]]; then
        # Create a backup with timestamp of audit log
        TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
        ROTATED_LOG="${AUDIT_LOG}_$TIMESTAMP.gz"

        # Compress the audit log and create a backup
        gzip -c "$AUDIT_LOG" > "$ROTATED_LOG"
        echo "Audit log rotated: $ROTATED_LOG"
        # Clear the audit log file
        : > "$AUDIT_LOG"

        # Check if number of rotated logs exceeds MAX_ROTATED_LOGS, if so delete the oldest
        BACKUPS=( $(ls -1t ${AUDIT_LOG}_*.gz 2>/dev/null) )
        while [ "${#BACKUPS[@]}" -gt "$MAX_ROTATED_LOGS" ]; do
            rm -f "${BACKUPS[-1]}"
            unset 'BACKUPS[-1]'
            echo "Old rotated log deleted: ${BACKUPS[-1]}"
        done
    fi
}

#-----------------------------------
# Function: Send alert (Email / Slack)
#-----------------------------------
send_alert () {
    local message="$1"

    if [[ "$ALERT_STATUS" != "enabled" ]]; then
        echo "Alerts are disabled in ./config.conf. No alert will be sent."
        return 0
    fi

    if [[ -z "$NOTIFICATION_EMAIL" && -z "$SLACK_WEBHOOK_URL" ]]; then
        echo "Notification email or Slack webhook URL is not set. Cannot send alert."
        echo "Configure NOTIFICATION_EMAIL or SLACK_WEBHOOK_URL in config.conf"
        return 1
    fi

    if [[ "${NOTIFICATION_METHOD,,}" == "slack" ]]; then
        # Send alert to Slack channel
        curl -s -X POST -H 'Content-type: application/json' \
             --data "{\"text\": \"$message\"}" \
             "$SLACK_WEBHOOK_URL"
        echo "Alert sent to Slack channel."

    elif [[ "${NOTIFICATION_METHOD,,}" == "email" ]]; then
        # Send alert via email
        if command -v mailx &> /dev/null; then
            echo "$message" | mailx -s "Log Alert Notification" "$NOTIFICATION_EMAIL"

            echo "Alert email sent to $NOTIFICATION_EMAIL."
        else
            echo "mail command not found. Please install mailutils package to send email alerts."
            return 1
        fi
    else
        echo "Invalid NOTIFICATION_METHOD specified in config.conf. Use 'slack' or 'email'."
    fi
}

#-----------------------------------
# Main monitoring loop
#-----------------------------------

tail -F "${LOG_FILES[@]}" | grep --line-buffered -iHE "$REGEX_PATTERN" | while read -r line; do
    # Rotate audit log if it exceeds size limit
    rotate_audit_log
    message="[ALERT]: $(date '+%Y-%m-%d %H:%M:%S') - $line"
    echo "$message" >> "$AUDIT_LOG"
    send_alert "$message"
    echo "[ALERT]: $(date '+%Y-%m-%d %H:%M:%S') - $line"

done