# Azure Lab environment

In this lab, we will configure a public Puppetserver on Azure and a RPi4 node.

To get an idea of the system configuration, see [here](https://puppet.com/docs/pe/2019.8/system_configuration.html).

## Puppetserver Cloud image
Before going to interconnect the Azure cloud environment, let's start with provisioning the puppetserver cloud image.

On the Azure marketplace, the latest available cloud image is pe2019.8.11. You can go through through the UI dialog steps to configure a puppetserver. As alternative, you can run a scripted install.

### Scripted install
The following script [Puppet-Install.ps1](https://github.com/dcasota/puppetlabs-scripts/blob/main/Azure/Puppet-Install.ps1) provisions the vm.
```
./Puppet-Install.ps1 -ResourceGroupName <your resource group> -Location <your location> -VMName <your name puppetserver>
```
Prerequisites are:
- Script must run on MS Windows OS with Powershell PSVersion 5.1 or higher
- Azure account with Virtual Machine contributor role

The script supports many additional parameters. It can be used for more advanced lab setups as well.

It may take a while until the puppetserver vm is up and running. Meanwhile connect with ssh using the localadmin credentials, and run ```sudo /opt/puppetlabs/cloud/bin/check_status.sh --wait```. Wait until the configuration process has finished.  

![pe-services](https://user-images.githubusercontent.com/14890243/178111433-82c9e342-8c4b-4926-af9a-e101c3f5a353.png)
  

### First run  
  
#### Wrong Publisher+Product is displayed when creating a puppet vm from marketplace
The script uses ```Set-AzMarketplaceTerms```. Not sure why but at that point a wrong publisher+productname is displayed. Maybe the Azure community can help?
https://docs.microsoft.com/en-us/answers/questions/917999/wrong-publisherproduct-is-displayed-when-creating.html

#### Console Password
In the docs it is written that you can set the console_password with ```sudo /opt/puppetlabs/puppet/bin/puppet infrastructure console_password --password=<yourpassword>```. You must be logged-in as root to run the command - obviously without sudo then, see https://tickets.puppetlabs.com/browse/ENTERPRISE-1352.

![pepasswordchange](https://user-images.githubusercontent.com/14890243/178112489-c9b19806-713e-448d-85a3-8eca702951fc.png)

Now login on the console.  

<img src="https://user-images.githubusercontent.com/14890243/178112692-1f42c432-d784-4e61-bc94-72af1f479ce6.png" align="left" height="300" width="210" />
<br clear="left"/><br clear="both"/>

The console appears.

![peloggedin](https://user-images.githubusercontent.com/14890243/178112702-7e423664-2131-4b8c-8512-26ea77222ad9.png)


## Puppet Agent on VMware Photon OS on Raspberry Pi 4

VMware Photon OS is a minimal container host Linux optimized to run on VMware platforms but capable of running in other environments as well. See [here](https://vmware.github.io/photon/) and [here](https://github.com/dcasota/photonos-scripts).

You can find [here](https://github.com/dcasota/photonos-scripts/wiki/Configure-a-complete-Raspberry-Pi-Virtualhere-installation) a description on how to install and configure the operating system, that said, provisioned without any automation tools. Instead of the Virtualhere installation part, install the puppet agent bits.

Since quite a while Puppetlabs supports Puppet agent on aarch64 as well. Unfortunately there is no tdnf package (tiny dandified yum) of Puppet agent on Photon OS, but you can download the rpm from https://yum.puppetlabs.com/puppet. Here's the installation recipe - it installs the rhel 7.9 puppet agent.

```
# change ip and fqdn to your lab environment
export PUPPETSERVER_IP=20.203.142.11
export PUPPETSERVER_FQDN=puppetmaster.sttfmguzm4zuhep0f2vmuubvca.zrhx.internal.cloudapp.net

cat <<EOF >>/etc/hosts
$PUPPETSERVER_IP  $PUPPETSERVER_FQDN
EOF
curl -J -O -L https://yum.puppetlabs.com/puppet/el/7/aarch64/puppet-agent-7.9.0-1.el7.aarch64.rpm
rpm -i puppet-agent-7.9.0-1.el7.aarch64.rpm
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true
ln -s /opt/puppetlabs/bin/puppet /bin
export PATH=/opt/puppetlabs/bin:$PATH
puppet config set server $PUPPETSERVER_FQDN --section main
puppet ssl bootstrap
```

With default settings, the puppetserver does not know that agent' certificate.  

<img src="https://user-images.githubusercontent.com/14890243/178143903-ca05742d-3bf9-4046-b9a5-3b8474615af4.png" align="left" height="120" width="600" />
<br clear="left"/><br clear="both"/>

You can sign agent's certificate eg. on the puppetserver UI.  

![pecertagent](https://user-images.githubusercontent.com/14890243/178143022-e2162711-24ed-4ca0-9adb-8499e010c0ae.png)

On the RPI4, rerun ```puppet ssl bootstrap```. Now the command completes successfully. Run ```puppet agent --test```, too.

After that, the node is fully available on puppetserver node.

Eg. check the node facts.

![peagentinfo](https://user-images.githubusercontent.com/14890243/178144125-e9af06bf-0ea6-4d7c-b04d-9d36989f74cf.png)

# Lab findings

## Setup

The lab setup is pretty straightforward. Some considerations for a next, more advanced setup could be:
- Add Puppet ci/cd examples
- Networking: eg. Azure Private Cloud with restricted VNET and RPI4 VPN connectivity, cloud image rework for Azure GenV2 to support secureboot+tpm, TLS1.3 standardization, etc.
- Monitoring: Longterm workload considerations for Puppetserver, eg. justification for vm size Standard_A4_v2, additional disk.
- Troubleshoot knowledge, considering availability + scaling

