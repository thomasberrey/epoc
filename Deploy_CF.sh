#!/bin/bash

### CF Deployment ###
rm -rf ~/workspace/cf*

bosh -e vbox upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent
bosh -e vbox stemcells

cd ~/workspace
git clone https://github.com/cloudfoundry/cf-deployment
cd cf-deployment

bosh -e vbox update-cloud-config iaas-support/bosh-lite/cloud-config.yml

cd ~/workspace
bosh -e vbox update-runtime-config <(bosh int bosh-deployment/runtime-configs/dns.yml --vars-store deployment-vars.yml) --name dns

cd cf-deployment

bosh -e vbox -d cf deploy cf-deployment.yml \
  -o operations/bosh-lite.yml \
  --vars-store deployment-vars.yml \
  -v system_domain=bosh-lite.com

bosh -e vbox -d cf instances

sudo route add -net 10.244.0.0/16 192.168.50.6

cf api https://api.bosh-lite.com --skip-ssl-validation
export CF_ADMIN_PASSWORD=$(bosh int ./deployment-vars.yml --path /cf_admin_password)
cf auth admin $CF_ADMIN_PASSWORD
export UAA_PASSWORD=$(bosh int ./deployment-vars.yml --path /uaa_admin_client_secret)

cf create-org "mycloud"
cf target -o "mycloud"
cf create-space dev
cf target -o "mycloud" -s "dev"

cd ~/workspace
git clone https://github.com/vchrisb/cf-helloworld cf-helloworld
cd ~/workspace/cf-helloworld
cf push
