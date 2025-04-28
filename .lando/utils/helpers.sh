 #!/usr/bin/env bash

set -e

source "$LANDO_MOUNT/.lando/utils/log.sh"

# Function to check and install a command if it doesn't exist
check_and_abort_if_missing() {
  local command="$1"
  if [[ ! $(command_exists "$command") ]]; then
    log_error "$command is required but not installed. Aborting." >&2
    exit 1
  fi
}

copy_ssh_key_to_remote() {
  local remote_host="$1"
  local pub_key="$2"

  log_info "Copying SSH key to remote host: $remote_host"

  # Check if the key already exists
  key_exists=$(ssh "$remote_host" "grep -qF \"$(cat ~/.ssh/$pub_key)\" ~/.ssh/authorized_keys")
  if [[ $? -eq 0 ]]; then
    log_info "Key already exists on $remote_host, skipping."
    return 0
  fi

  if command -v ssh-copy-id &> /dev/null; then
    ssh-copy-id -i ~/.ssh/"$pub_key" "$remote_host"
    if [[ $? -ne 0 ]]; then
      log_error "ssh-copy-id failed for $remote_host"
      return 1
    fi
  else
    cat ~/.ssh/"$pub_key" | ssh "$remote_host" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    if [[ $? -ne 0 ]]; then
      log_error "Manual SSH key copy failed for $remote_host"
      return 1
    fi
  fi
  log_info "SSH key copied successfully to $remote_host"
  return 0
}

uninstall_plugins() {
  for plugin in $1 ; do
    wp plugin is-installed $plugin 2>/dev/null

    if [[ "$?" = "0" ]] ; then
      wp plugin uninstall $plugin
    fi
  done
}

# Detect whether WP is installed
wp_installed() {
  wp --quiet core is-installed
  [[ $? = '0' ]] && return
  false
}
