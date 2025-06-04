#!/bin/bash

# Fail fast on errors
set -e

# Get the EC2 public IP from Terraform
EC2_IP=$(terraform -chdir=../terraform output -raw ec2_public_ip)

# Check if the IP was retrieved
if [[ -z "$EC2_IP" ]]; then
  echo "❌ ERROR: ec2_public_ip not available from Terraform."
  exit 1
fi

# Use env vars from Jenkins
SSH_USER="${SSH_USER:-ubuntu}"
PEM_PATH="${PEM_KEY}"

# Generate the inventory directly
cat <<EOF > inventory.yml
all:
  hosts:
    rails-app:
      ansible_host: $EC2_IP
      ansible_user: $SSH_USER
      ansible_ssh_private_key_file: $PEM_PATH
EOF
