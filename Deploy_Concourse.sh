#!/bin/bash

### Concourse Deployment ###
rm -rf ~/workspace/concourse*

bosh -e vbox upload-stemcell \
  https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent?v=315.45 \
  --sha1 674cd3c1e64d8c51e62770697a63c07ca04e9bbd
bosh -e vbox stemcells

cd ~/workspace
git clone https://github.com/concourse/concourse-bosh-deployment.git
cd ~/workspace/concourse-bosh-deployment/cluster

bosh -e vbox update-cloud-config cloud_configs/vbox.yml

bosh -e vbox deploy -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store cluster-creds.yml \
  -o operations/static-web.yml \
  -o operations/basic-auth.yml \
  --var local_user.username=admin \
  --var local_user.password=admin \
  --var web_ip=10.244.15.2 \
  --var external_url=http://10.244.15.2:8080 \
  --var network_name=concourse \
  --var web_vm_type=concourse \
  --var db_vm_type=concourse \
  --var db_persistent_disk_type=db \
  --var worker_vm_type=concourse \
  --var deployment_name=concourse

sudo route add -net 10.244.0.0/16 192.168.50.6
fly -t ci login -c http://10.244.15.2:8080 -u admin -p admin
