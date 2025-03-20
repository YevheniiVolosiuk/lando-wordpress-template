#!/usr/bin/env bash

set -e

# $LANDO_MOUNT path to a root directory of the application
cd "$LANDO_MOUNT"/public

# Check if WordPress is already installed
if ! $(wp core is-installed); then
  echo "WordPress is not installed. Starting installation..."

  # Download WordPress (English - US)
  wp core download --locale=en_US

  # Create the wp-config.php file
  wp config create \
    --dbname=wordpress \
    --dbuser=wordpress \
    --dbpass=password \
    --dbhost=database

  # Install WordPress
  wp core install \
    --url="https://$LANDO_APP_NAME.$LANDO_DOMAIN/" \
    --title="Lando WordPress" \
    --admin_user=admin \
    --admin_password=password \
    --admin_email="admin@admin.com" \

  echo "WordPress installed successfully."

else
  echo "WordPress is already installed."
fi

if [[ ! -e "$LANDO_MOUNT/vendor" ]]; then
     cd $LANDO_MOUNT
     composer install
fi
#
# if [[ ! -e "$LANDO_MOUNT/node_modules" ]]; then
#     cd "$LANDO_MOUNT"
#     npm install
# fi