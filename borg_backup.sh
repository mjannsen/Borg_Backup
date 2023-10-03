#!/bin/bash

BORG_REPO="/mnt/backup/borg_backup"
declare -a BACKUP_SOURCES=(
  "/some/path/to/files"
  "/some/path/to/files"
)

# Here we store our DB Credentials
DB_CONFIG_FILE="/root/dbconfig.cnf"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
LOGFILE="/var/log/borg_backup.log"

log_message() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# Check available disk space and store it in a variable
MIN_FREE_SPACE_GB=10
available_space_gb=$(df -BG "$BORG_REPO" | awk 'NR==2 {gsub("G","",$4); print $4}')

# Compare available space with the minimum required space
if ((available_space_gb >= MIN_FREE_SPACE_GB)); then
  echo "There is at least 10GB of free space. Proceeding with backup..."
else
  echo "Error: Insufficient free space. Aborting backup."
  exit 1
fi

log_message "Starting database backup..."
if mysqldump --defaults-extra-file=$DB_CONFIG_FILE nextcloud > /root/db_backup.sql 2>> "$LOGFILE"; then
  log_message "Database backup completed successfully."
else
  log_message "Database backup failed."
  exit 1
fi

for SOURCE_DIR in "${BACKUP_SOURCES[@]}"
do
  log_message "Starting backup of $SOURCE_DIR..."
  if borg create --compression lz4 $BORG_REPO::${TIMESTAMP}_${SOURCE_DIR//\//-} $SOURCE_DIR /root/db_backup.sql 2>> "$LOGFILE"; then
    log_message "Backup of $SOURCE_DIR completed successfully."
  else
    log_message "Backup of $SOURCE_DIR failed."
  fi
done

rm /root/db_backup.sql

# Perform backup validation using Borg check and capture output
log_message "Starting backup validation..."
if borg check $BORG_REPO 2>> "$LOGFILE"; then
  log_message "Backup validation completed successfully."
else
  log_message "Backup validation failed."
fi

log_message "Pruning old backups..."
if borg prune -v --list $BORG_REPO --prefix "${TIMESTAMP}" --keep-daily=7 --keep-weekly=4 --keep-monthly=6 >> "$LOGFILE" 2>&1; then
  log_message "Pruning completed successfully."
else
  log_message "Pruning failed."
fi
