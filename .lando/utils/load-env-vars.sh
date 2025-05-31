#!/usr/bin/env bash

set -e

source "$LANDO_MOUNT/.lando/utils/log.sh"

# Load environment variables from .env file
if [[ -f .env ]]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
else
  log_error "No .env file found. Aborting."
  exit 1
fi
