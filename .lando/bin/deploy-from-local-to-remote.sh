#!/usr/bin/env bash

# deploy-from-local-to-remote.sh - Deploys WordPress Project from local to remote environment
# This script synchronizes database and files from a local Lando WordPress installation to a remote server

# Exit on any error
set -e

# Source utility scripts
source "$LANDO_MOUNT/.lando/utils/helpers.sh"
source "$LANDO_MOUNT/.lando/utils/load-env-vars.sh"
source "$LANDO_MOUNT/.lando/utils/log.sh"

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1 || { log_error "Required command '$1' not found. Please install it."; exit 1; }
}

# Function to export database from local environment
export_database_locally() {
  log_info "Exporting local database..."

  # Create tmp directory if it doesn't exist
  mkdir -p "$LANDO_MOUNT/.lando/tmp"

  if [[ -f "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP" ]]; then
    log_info "Deleted old backup file and replacing with a new latest version."
    rm -f "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP"
  fi

  # Export database locally
  php -d error_reporting=0 -d display_errors=0 $(which wp) --path="$LOCAL_WP_PATH" db export --net-buffer-length=16384 --max-allowed-packet=512M - 2>/dev/null | gzip > "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP"

  if [[ $? -ne 0 ]]; then
    log_error "Failed to export local database. Aborting."
    exit 1
  fi

  log_success "Local database exported successfully to $LANDO_MOUNT/.lando/tmp/$DB_BACKUP"
}

# Function to sync files from local to remote
sync_files_from_local_to_remote() {
  log_info "Syncing files from ./$LOCAL_PATH to $REMOTE_HOST:$REMOTE_PATH..."

  # Use rsync with progress indicator and exclusions
  rsync -avz --progress \
    --exclude='cache/' \
    --exclude='.env' \
    --exclude='uploads/cache/' \
    --exclude='plugins/spinupwp/' \
    --exclude='backup-*/' \
    --exclude='*.log' \
    --exclude='*.zip' \
    --exclude='debug.log' \
    --exclude='object-cache.php' \
    --exclude='.DS_Store' \
    --delete \
    "./$LOCAL_PATH/" \
    "$REMOTE_HOST:${REMOTE_PATH}/"

  if [[ $? -ne 0 ]]; then
    log_error "Failed to sync files to remote. Aborting."
    exit 1
  fi

  log_success "Files synced successfully."
}

# Function to import database to remote environment
import_database_to_remote() {
  log_info "Importing database to remote environment..."

  # Copy the database backup to the remote server
  scp "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP" "$REMOTE_HOST:${REMOTE_PATH}/$DB_BACKUP"

  if [[ $? -ne 0 ]]; then
    log_error "Failed to copy database backup to remote server. Aborting."
    exit 1
  fi

  # Execute commands on remote server to reset and import the database
  gunzip -c "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP" | ssh "$REMOTE_HOST" "wp --path='${REMOTE_WP_PATH}' db reset --yes && wp --path='${REMOTE_WP_PATH}' db import - --dbhost=localhost --dbname=${REMOTE_DB_NAME} --dbuser=${REMOTE_DB_USER} --dbpass=${REMOTE_DB_PASS}"

  if [[ $? -ne 0 ]]; then
    log_error "Failed to import database on remote server. Aborting."
    exit 1
  fi

  log_success "Database imported successfully on remote server."
}

# Function to update URLs and clean up
update_remote_urls_and_cleanup() {
  log_info "Updating URLs from $LOCAL_DOMAIN to $REMOTE_DOMAIN on remote server..."

  # Search and replace URLs on remote server
  ssh "$REMOTE_HOST" "wp --path='${REMOTE_WP_PATH}' search-replace 'https://$LOCAL_DOMAIN' 'https://$REMOTE_DOMAIN' --all-tables && \
    wp --path='${REMOTE_WP_PATH}' search-replace 'http://$LOCAL_DOMAIN' 'https://$REMOTE_DOMAIN' --all-tables && \
    wp --path='${REMOTE_WP_PATH}' search-replace '$LOCAL_DOMAIN' '$REMOTE_DOMAIN' --all-tables && \
    wp --path='${REMOTE_WP_PATH}' cache flush"

  if [[ $? -ne 0 ]]; then
    log_error "Failed to update URLs on remote server. Aborting."
    exit 1
  fi

  # Remove local backup file
  rm -f "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP"

  log_success "URL replacement and cleanup completed on remote server."
}

# Main script execution starts here
log_info "Starting WordPress deployment from local to remote..."

# Validate environment variables
LOCAL_PATH="${LOCAL_PATH:?Local path not set}"
LOCAL_WP_PATH="${LOCAL_WP_PATH:?Local wordpress path not set}"
LOCAL_DOMAIN="${LOCAL_DOMAIN:?Local site URL not set}"
REMOTE_HOST="${REMOTE_HOST:?Remote host not set (username@ip.address)}"
REMOTE_PATH="${REMOTE_PATH:?Remote path not set}"
REMOTE_WP_PATH="${REMOTE_WP_PATH:?Remote wordpress path not set}"
REMOTE_DOMAIN="${REMOTE_DOMAIN:?Remote site URL not set}"
REMOTE_DB_NAME="${REMOTE_DB_NAME:?Remote database name not set}"
REMOTE_DB_USER="${REMOTE_DB_USER:?Remote database user not set}"
REMOTE_DB_PASS="${REMOTE_DB_PASS:?Remote database password not set}"

# Generate timestamp for backup
TIMESTAMP=$(date +%Y%m%d)
DB_BACKUP="wp_backup_${TIMESTAMP}.sql.gz"

# Check if required commands exist
command_exists "ssh"
command_exists "wp"
command_exists "rsync"
command_exists "gzip"
command_exists "scp"

# Execute the deployment process
export_database_locally
sync_files_from_local_to_remote
import_database_to_remote
update_remote_urls_and_cleanup

log_success "WordPress deployment completed successfully!"
exit 0
