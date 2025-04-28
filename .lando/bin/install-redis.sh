#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and catch errors in pipelines.
set -euo pipefail

source "$LANDO_MOUNT/.lando/utils/log.sh"

# Move to the public WordPress directory
cd "$LANDO_MOUNT/public"

# Ensure wp-cli is available
command -v wp >/dev/null 2>&1 || log_error "wp-cli is not installed or not available."

log_info "Configuring WordPress for Redis caching..."

# Set Redis server connection settings in wp-config.php
wp config set WP_REDIS_HOST cache
wp config set WP_REDIS_PORT 6379 --raw

log_info "Installing and activating Redis Cache plugin..."

# Install and activate the Redis Object Cache plugin if it's not active
if ! wp plugin is-installed redis-cache; then
  wp plugin install redis-cache --activate
else
  wp plugin activate redis-cache
fi

log_info "Enabling Redis Object Cache in WordPress..."

# Enable Redis object cache
wp redis enable

log_info "Redis caching setup completed successfully! 🚀"
