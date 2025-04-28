#!/usr/bin/env bash
set -eo pipefail

source "$LANDO_MOUNT/.lando/utils/log.sh"
source "$LANDO_MOUNT/.lando/utils/helpers.sh"

# $LANDO_MOUNT path to a root directory of the wp installation
cd "$LANDO_MOUNT"/public

# Only run once
if [ -f "./wp-config.php" ]; then
  log_info "wp-config.php exists – WordPress is likely set up. Skipping setup."
  exit 0
fi

log_info "Downloading WordPress core..."
wp core download --path=./ --locale="${WP_LOCALE:-en_US}"

log_info "Creating wp-config.php..."
wp config create \
   --dbname="${DB_NAME:-wordpress}" \
   --dbuser="${DB_USER:-wordpress}" \
   --dbpass="${DB_PASSWORD:-wordpress}" \
   --dbhost="${DB_HOST:-database}" \
   --dbprefix="${DB_PREFIX:-wp_}" \
   --skip-salts

log_info "Generating authentication salts..."
wp config shuffle-salts

log_info "Installing WordPress..."
wp core install \
   --url="https://$LANDO_APP_NAME.$LANDO_DOMAIN/" \
   --title="${WP_SITE_TITLE:-My WordPress Site}" \
   --admin_user="${WP_ADMIN_USER:-admin}" \
   --admin_password="${WP_ADMIN_PASS:-password}" \
   --admin_email="${WP_ADMIN_EMAIL:-admin@admin.com}"

log_info "WordPress setup complete."
