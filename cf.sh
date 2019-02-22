sudo apt-get install ruby &&
sudo apt-get install git &&
sudo apt-get install gdebi &&
wget "http://download.virtualbox.org/virtualbox/5.1.22/virtualbox-5.1_5.1.22-115126~Ubuntu~xenial_amd64.deb" &&
gdebi virtualbox-5.1_5.1.22-115126~Ubuntu~xenial_amd64.deb && # NOT Working!
notify-send "virtualbox Installed"
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add - &&
echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list &&
sudo apt-get update &&
sudo apt-get install cf-cli &&
notify-send "cf-cli Installed" &&
wget "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.42-linux-amd64" &&
chmod +x bosh-cli-* &&   # pwd
sudo mv bosh-cli-* /usr/local/bin/bosh &&  #pwd
git clone https://github.com/cloudfoundry/bosh-deployment ~/workspace/bosh-deployment &&
mkdir -p ~/deployments/vbox &&
cd ~/deployments/vbox &&
bosh create-env ~/workspace/bosh-deployment/bosh.yml \
  --state ~/deployments/vbox/state.json \
  -o ~/workspace/bosh-deployment/virtualbox/cpi.yml \
  -o ~/workspace/bosh-deployment/virtualbox/outbound-network.yml \
  -o ~/workspace/bosh-deployment/bosh-lite.yml \
  -o ~/workspace/bosh-deployment/bosh-lite-runc.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  --vars-store ~/deployments/vbox/creds.yml \
  -v director_name="Bosh Lite Director" \
  -v internal_ip=192.168.50.6 \
  -v internal_gw=192.168.50.1 \
  -v internal_cidr=192.168.50.0/24 \
  -v outbound_network_name=NatNetwork &&
bosh -e 192.168.50.6 --ca-cert <(bosh int ~/deployments/vbox/creds.yml --path /director_ssl/ca) alias-env vbox &&
export BOSH_CA_CERT=$(bosh int ~/deployments/vbox/creds.yml --path /director_ssl/ca) &&
export BOSH_CLIENT=admin &&
export BOSH_CLIENT_SECRET=$(bosh int ~/deployments/vbox/creds.yml --path /admin_password) &&
export BOSH_ENVIRONMENT=vbox &&
git clone https://github.com/cloudfoundry/cf-deployment ~/workspace/cf-deployment &&
cd ~/workspace/cf-deployment &&
export STEMCELL_VERSION=$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path /stemcells/alias=default/version) &&
bosh upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=$STEMCELL_VERSION &&
bosh update-cloud-config ~/workspace/cf-deployment/iaas-support/bosh-lite/cloud-config.yml &&
notify-send "Deploying Cloud Foundry Release" &&
bosh -d cf deploy ~/workspace/cf-deployment/cf-deployment.yml -o ~/workspace/cf-deployment/operations/bosh-lite.yml --vars-store ~/deployments/vbox/deployment-vars.yml -v system_domain=bosh-lite.com &&
notify-send "Deployment of Cloud Foundry Release Completed" &&
sudo route add -net 10.244.0.0/16 gw 192.168.50.6 &&
cf login -a https://api.bosh-lite.com --skip-ssl-validation -u admin -p $(bosh interpolate ~/deployments/vbox/deployment-vars.yml --path /cf_admin_password) &&
notify-send "Logged in as Admin" &&
cf create-org cloudfoundry &&
cf target -o cloudfoundry &&
cf create-space development &&
cf target -o cloudfoundry -s development &&
notify-send "Org and space created. Installation Completed Successfully" &&
git clone https://github.com/vchrisb/cf-helloworld ~/workspace/cf-helloworld &&
cd ~/workspace/cf-helloworld &&
cf push &&
notify-send "Pushed Hello World to Cloud Foundry" &&
cf enable-feature-flag diego_docker &&
cf push test-app -o cloudfoundry/test-app &&
notify-send "Process Completed!!";



