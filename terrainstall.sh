#!/bin/bash

# Exit on any error
set -e

echo "[+] Downloading Terraform 1.7.5..."
curl -O https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip

echo "[+] Unzipping Terraform..."
unzip -o terraform_1.7.5_linux_amd64.zip

echo "[+] Moving Terraform binary to /usr/local/bin..."
sudo mv terraform /usr/local/bin/
