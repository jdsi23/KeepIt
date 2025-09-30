#!/bin/bash

set -e 
chmod +x terrainstall.sh
./terrainstall.sh

cd keepit-infra
terraform init
terraform workspace new dev || true
terraform workspace select dev
terraform apply -var-file=env/dev.tfvars
