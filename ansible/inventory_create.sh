#!/bin/bash
EC2_IP=$(terraform -chdir=../terraform output -raw instance_public_ip)
export ec2_ip=$EC2_IP
envsubst < inventory.yml.j2 > inventory.yml
echo "Inventory file created with EC2 IP: $EC2_IP"
