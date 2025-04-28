#!/usr/bin/env bash

set -e

log_info() {
  echo -e "\e[32m[INFO] $1\e[0m"
}

log_error() {
  echo -e "\e[31m[ERROR] $1\e[0m"
}

dd() {
  echo -e "\e[34m[DEBUG] $1\e[0m"
}