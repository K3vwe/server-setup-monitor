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

# function to check and rotate audit log if it exceeds 5MB
# if so create a compressed backup and clear the file
rotate_audit_log () {
    # Check if the audit file exists and check if the audit log size is greater than 5MB,
    if [ [ -f "$AUDIT_LOG"] && [ "$(stat -c%s "$AUDIT_LOG")" -ge "$LOG_ROTATION_SIZE" ]]; then
        # Create a backup with timestamp of audit log
        TIMESTAMP= $(date '+%Y%m%d_%H%M%S')
        ROTATED_LOG="${AUDIT_LOG}_$TIMESTAMP.gz"

        # Compress the audit log and create a backup
        gzip -c "$AUDIT_LOG" > "$ROTATED_LOG"
        echo "Audit log rotated: $ROTATED_LOG"
        # Clear the audit log file
        : > "$AUDIT_LOG"

        # Check if number of rotated logs exceeds MAX_ROTATED_LOGS, if so delete the oldest
        BACKUP=( $(ls -1t ${AUDIT_LOG}_*.gz 2>/dev/null) )
        while [ "${#BACKUP[@]}" -gt "$MAX_ROTATED_LOGS" ]; do
            rm -f "${BACKUP[-1]}"
            unset 'BACKUP[-1]'
            echo "Old rotated log deleted: ${BACKUP[-1]}"
        done
    fi
}

tail -F "${LOG_FILES[@]}" | grep --line-buffered -iHE "$REGEX_PATTERN" | while read -r line; do
    # Rotate audit log if it exceeds size limit
    rotate_audit_log
    echo "$line" >> "$AUDIT_LOG"
    echo "[ALERT]: $(date '+%Y-%m-%d %H:%M:%S') - $line"

done