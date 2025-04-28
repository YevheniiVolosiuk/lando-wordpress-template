#!/usr/bin/env bash
set -euo pipefail

source "$LANDO_MOUNT/.lando/utils/log.sh"

# $LANDO_MOUNT path to a root directory of the wp installation
cd "$LANDO_MOUNT"/public

# Variables
WP_URL="https://${LANDO_APP_NAME}.${LANDO_DOMAIN}/"
TIMEZONE="Europe/Warsaw"
DATE_FORMAT="Y-m-d"
TIME_FORMAT="H:i"

# Ensure wp-cli is available
command -v wp >/dev/null 2>&1 || log_error "wp-cli is not installed or not available."

log_info "Starting post-installation setup..."

# Core Setup
log_info "Updating site settings..."
wp option update blog_infodescription "Just another Lando WordPress site"
wp option update timezone_string "$TIMEZONE"
wp option update date_format "$DATE_FORMAT"
wp option update time_format "$TIME_FORMAT"
wp option update blog_public 0  # Discourage search engines
wp rewrite structure '/%category%/%postname%/' --hard
wp rewrite flush --hard

# Clean default content
log_info "Deleting default posts, pages, and comments..."
wp post delete $(wp post list --post_type='post' --format=ids) --force || true
wp post delete $(wp post list --post_type='page' --format=ids) --force || true
wp comment delete $(wp comment list --format=ids) --force || true

# Disable comments sitewide
log_info "Disabling comments sitewide..."
wp option update default_comment_status closed
wp option update default_ping_status closed
wp post list --format=ids | xargs -r -I % wp post meta update % _comment_status closed || true

# Create Home and Blog pages
log_info "Creating Home and Blog pages..."
if ! wp post list --post_type=page --name=home --format=ids | grep -q .; then
  wp post create --post_type=page --post_title='Home' --post_status=publish
fi
if ! wp post list --post_type=page --name=blog --format=ids | grep -q .; then
  wp post create --post_type=page --post_title='Blog' --post_status=publish
fi

HOME_ID=$(wp post list --post_type=page --name=home --field=ID --format=ids)
BLOG_ID=$(wp post list --post_type=page --name=blog --field=ID --format=ids)

log_info "Setting Home page and Blog_info page..."
wp option update show_on_front page
wp option update page_on_front "$HOME_ID"
wp option update page_for_posts "$BLOG_ID"


log_info "Uninstall stock plugins..."
wp --quiet plugin uninstall \
    hello \
    akismet

log_info "Uninstall stock themes..."
wp --quiet theme uninstall \
  twentytwentythree \
  twentytwentyfour

# Install and activate essential plugins
log_info "Installing essential plugins..."
wp plugin install secure-custom-fields admin-site-enhancements  query-monitor debug-bar wp-crontrol --activate

# Theme Menus
log_info "Setting up menus..."
MAIN_MENU_ID=$(wp menu create "Main Menu" --porcelain || true)
FOOTER_MENU_ID=$(wp menu create "Footer Menu" --porcelain || true)

THEME_LOCATIONS=$(wp theme mod list --field=key)

if echo "$THEME_LOCATIONS" | grep -q 'primary'; then
  wp menu location assign "$MAIN_MENU_ID" primary
fi

if echo "$THEME_LOCATIONS" | grep -q 'footer'; then
  wp menu location assign "$FOOTER_MENU_ID" footer
fi

# Disable file editing in WP Admin
log_info "Disabling file editing and auto-updates..."
wp config set DISALLOW_FILE_EDIT true --raw
wp config set AUTOMATIC_UPDATER_DISABLED true --raw
wp config set WP_AUTO_UPDATE_CORE false --raw

# Clean uploads folder
UPLOADS_DIR="$(wp option get upload_path)"
if [ -d "$UPLOADS_DIR" ]; then
  log_info "Cleaning uploads directory..."
  rm -rf "${UPLOADS_DIR:?}"/*
fi

# Final Cleanup and flush
log_info "Flushing permalinks..."
wp rewrite flush --hard

log_info "Post-installation setup completed successfully! 🚀"
