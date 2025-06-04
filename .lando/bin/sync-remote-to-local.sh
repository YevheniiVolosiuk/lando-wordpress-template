#!/usr/bin/env bash

# sync-remote-to-local.sh - Syncs WordPress Project from remote to local environment
# This script synchronizes database and files from a remote WordPress installation to a local Lando environment

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

# Function to export database from remote server
export_database_remotely() {
  log_info "Exporting remote database..."

  # Create tmp directory if it doesn't exist
  mkdir -p "$LANDO_MOUNT/.lando/tmp"

  if [[ -f "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP" ]]; then
    log_info "Deleted old backup file and replacing with a new latest version."
    rm -f $LANDO_MOUNT/.lando/tmp/$DB_BACKUP
  fi

  # Export database directly through SSH pipeline to avoid temporary files on remote server
  ssh "$REMOTE_HOST" "php -d error_reporting=0 -d display_errors=0 \$(which wp) db export --path=${REMOTE_WP_PATH} --net-buffer-length=16384 --max-allowed-packet=512M - 2>/dev/null | gzip" > "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP"

  if [[ $? -ne 0 ]]; then
    log_error "Failed to export remote database. Aborting."
    exit 1
  fi

  log_success "Remote database exported successfully."
}

# Function to sync files from remote to local
sync_files_from_remote_to_local() {
  log_info "Syncing files from $REMOTE_HOST:$REMOTE_PATH to ./$LOCAL_PATH..."

  # Use rsync with progress indicator and exclusions
  rsync -avz --progress \
    --exclude='.env' \
    --exclude='cache/' \
    --exclude='uploads/cache/' \
    --exclude='backup-*/' \
    --exclude='*.log' \
    --exclude='*.zip' \
    --exclude='debug.log' \
    --exclude='object-cache.php' \
    --exclude='.DS_Store' \
    --delete \
    "$REMOTE_HOST:${REMOTE_PATH}/" \
    "./$LOCAL_PATH/"

  if [[ $? -ne 0 ]]; then
    log_error "Failed to sync files from remote. Aborting."
    exit 1
  fi

  log_success "Files synced successfully."
}

# Function to import database to local environment
import_database_to_local() {
  log_info "Importing database to local environment..."

  # Reset the local database
  wp --path="$LOCAL_WP_PATH" db reset --yes

  # Extract and import the database
  gunzip -c "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP" | wp --path="$LOCAL_WP_PATH" db import - --dbhost=database --dbname=wordpress --dbuser=wordpress --dbpass=password

  if [[ $? -ne 0 ]]; then
    log_error "Failed to import database. Backup file is still available at $LANDO_MOUNT/.lando/tmp/$DB_BACKUP"
    exit 1
  fi

  log_success "Database imported successfully."
}

# Function to update URLs and clean up
update_urls_and_cleanup() {
  log_info "Updating URLs from $REMOTE_DOMAIN to $LOCAL_DOMAIN..."

  # Search and replace URLs
  wp --path="$LOCAL_WP_PATH" search-replace "https://$REMOTE_DOMAIN" "https://$LOCAL_DOMAIN" --all-tables
  wp --path="$LOCAL_WP_PATH" search-replace "http://$REMOTE_DOMAIN" "https://$LOCAL_DOMAIN" --all-tables
  wp --path="$LOCAL_WP_PATH" search-replace "$REMOTE_DOMAIN" "$LOCAL_DOMAIN" --all-tables

  # Flush cache
  wp --path="$LOCAL_WP_PATH" cache flush

  # Remove backup file
  rm -f "$LANDO_MOUNT/.lando/tmp/$DB_BACKUP"

  log_success "URL replacement and cleanup completed."
}

# Main script execution starts here
log_info "Starting WordPress sync from remote to local..."

# Validate environment variables
REMOTE_HOST="${REMOTE_HOST:?Remote host not set (username@ip.address)}"
REMOTE_PATH="${REMOTE_PATH:?Remote path not set}"
REMOTE_WP_PATH="${REMOTE_WP_PATH:?Remote wordpress path not set}"
REMOTE_DOMAIN="${REMOTE_DOMAIN:?Remote site URL not set}"
LOCAL_PATH="${LOCAL_PATH:?Local path not set}"
LOCAL_WP_PATH="${LOCAL_WP_PATH:?Local wordpress path not set}"
LOCAL_DOMAIN="${LOCAL_DOMAIN:?Local site URL not set}"

# Generate timestamp for backup
TIMESTAMP=$(date +%Y%m%d)
DB_BACKUP="wp_backup_${TIMESTAMP}.sql.gz"

# Check if required commands exist
command_exists "ssh"
command_exists "wp"
command_exists "rsync"
command_exists "gzip"
command_exists "gunzip"

# Execute the sync process
export_database_remotely
sync_files_from_remote_to_local
import_database_to_local
update_urls_and_cleanup

log_success "WordPress sync completed successfully!"
exit 0
