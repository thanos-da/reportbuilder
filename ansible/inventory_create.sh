#!/bin/bash

set -e

# Get IP from Terraform output
EC2_IP=$(terraform -chdir=../terraform output -raw ec2_public_ip)

# Validate
if [[ -z "$EC2_IP" ]]; then
  echo "❌ ERROR: Could not get ec2_public_ip from Terraform."
  exit 1
fi

# These env vars are passed from Jenkins
SSH_USER="${SSH_USER:-ubuntu}"
PEM_PATH="${PEM_KEY}"

# Write inventory.yml directly
cat <<EOF > inventory.yml
all:
  hosts:
    rails-app:
      ansible_host: $EC2_IP
      ansible_user: $SSH_USER
      ansible_ssh_private_key_file: $PEM_PATH
EOF
