#!/bin/bash

### Clean up Environment ###
VBoxManage list runningvms | awk '{print $2;}' | xargs -I vmid VBoxManage controlvm vmid poweroff
VBoxManage list vms | awk '{print $2;}' | xargs -I vmid VBoxManage unregistervm --delete vmid
rm -rf .bosh*
rm -rf ~/VirtualBox\ VMs/
rm -rf ~/workspace/bosh*
rm -rf ~/workspace/*deployment*
rm -rf ~/.ssh/

### BOSH Director Deployment ###
mkdir ~/workspace
cd ~/workspace
git clone https://github.com/cloudfoundry/bosh-deployment bosh-deployment

mkdir -p ~/workspace/deployments/vbox
cd ~/workspace/deployments/vbox

cp ~/workspace/bosh-deployment/virtualbox/cpi.yml ~/workspace/bosh-deployment/virtualbox/cpi.yml.orig
sed 's/6144/8192/g' ~/workspace/bosh-deployment/virtualbox/cpi.yml.orig > ~/workspace/bosh-deployment/virtualbox/cpi.yml

bosh create-env ~/workspace/bosh-deployment/bosh.yml \
  --state state.json \
  --vars-store ./creds.yml \
  -o ~/workspace/bosh-deployment/virtualbox/cpi.yml \
  -o ~/workspace/bosh-deployment/virtualbox/outbound-network.yml \
  -o ~/workspace/bosh-deployment/bosh-lite.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -v director_name=vbox \
  -v internal_ip=192.168.50.6 \
  -v internal_gw=192.168.50.1 \
  -v internal_cidr=192.168.50.0/24 \
  -v network_name=vboxnet0 \
  -v outbound_network_name=NatNetwork

cd ~/workspace/deployments
bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int vbox/creds.yml --path /director_ssl/ca)
bosh int vbox/creds.yml --path /admin_password
bosh -e vbox login

umask 077; touch ~/workspace/deployments/vbox/director_priv.key
bosh int ~/workspace/deployments/vbox/creds.yml --path /jumpbox_ssh/private_key > ~/workspace/deployments/vbox/director_priv.key
ssh jumpbox@192.168.50.6 -i ~/workspace/deployments/vbox/director_priv.key
