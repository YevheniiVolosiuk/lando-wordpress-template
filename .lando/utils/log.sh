#!/usr/bin/env bash

set -e

log_info() {
  echo -e "\e[34m[INFO] $1\e[0m"    # Keeping blue (34)
}

log_error() {
  echo -e "\e[31m[ERROR] $1\e[0m"   # Keeping red (31)
}

log_success() {
  echo -e "\e[32m[SUCCESS] $1\e[0m" # Keeping Green (32)
}

dd() {
  echo -e "\e[33m[DEBUG] $1\e[0m"   # Keeping orange/yellow (33)
}
