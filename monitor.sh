# Script: Continously monitor a set of log files for specifc error patterns and send alerts via email or slack 
# and store them in an audit log

#/bin/bash

# Exit immediately if a command fails
set -e

#Include logs
exec > >(tee -i /var/log/alert.log)
exec 2>&1

# Load Configuration Variables
source ./config.conf

# REGEX pattern to search for in log files
REGEX_PATTERN="$(IFS='|'; echo "${ERROR_PATTERNS[*]}")"

# Monitor log files for error patterns and save error lines to audit log
echo ">>> Monitoring log files for error patterns......."
echo "Log Files: ${LOG_FILES[*]}"
echo "Error Patterns: ${ERROR_PATTERNS[*]}"
echo "Audit Log: $AUDIT_LOG"
echo


tail -F "${LOG_FILES[@]}" | grep --line-buffered -iHE "$REGEX_PATTERN" | while read -r line; do
    echo "$line" >> "$AUDIT_LOG"
    echo "[ALERT]: $(date '+%Y-%m-%d %H:%M:%S') - $line"

done