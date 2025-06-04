#!/bin/bash

# Get single EC2 public IP from Terraform
EC2_IP=$(terraform -chdir=../terraform output -raw ec2_public_ip)

# Set user and PEM key path from environment variables passed from Jenkins
SSH_USER="${SSH_USER:-ubuntu}"
PEM_PATH="${PEM_KEY}"

# Write static inventory
cat <<EOF
all:
  hosts:
    rails-app:
      ansible_host: $EC2_IP
      ansible_user: $SSH_USER
      ansible_ssh_private_key_file: $PEM_PATH
EOF
