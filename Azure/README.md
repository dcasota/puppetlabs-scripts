# Azure Lab environment

In this lab, we will configure a public Puppetserver on Azure and a local RPi4 node.

The home lab infrastructure is dynamically allocated to save resources. You can cleanup the resources of the (Azure) environment and reprovision the lab as much needed for learning purposes. Keep in mind that the setup is not intended to use for a productive environment.

## Puppetserver Cloud image

Let's start with provisioning the puppetserver cloud image. To get an idea of the system configuration, see [here](https://puppet.com/docs/pe/2019.8/system_configuration.html).

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
The script uses ```Set-AzMarketplaceTerms```. Not sure why but at that point a wrong publishername+productname is displayed. Maybe the Azure community can help?
https://docs.microsoft.com/en-us/answers/questions/917999/wrong-publisherproduct-is-displayed-when-creating.html

#### Console Password
In the docs it is written that you can set the console_password with ```sudo /opt/puppetlabs/puppet/bin/puppet infrastructure console_password --password=<yourpassword>```. You must be logged-in as root to run the command - obviously without sudo then, see https://tickets.puppetlabs.com/browse/ENTERPRISE-1352.

![pepasswordchange](https://user-images.githubusercontent.com/14890243/178112489-c9b19806-713e-448d-85a3-8eca702951fc.png)

Now login on the console.  

<img src="https://user-images.githubusercontent.com/14890243/178112692-1f42c432-d784-4e61-bc94-72af1f479ce6.png" align="left" height="300" width="210" />
<br clear="left"/><br clear="both"/>

The console appears.

![peloggedin](https://user-images.githubusercontent.com/14890243/178112702-7e423664-2131-4b8c-8512-26ea77222ad9.png)

## Cleanup

Go to the next section if you haven't finished your Lab setup. This cleanup section is intended if you want to rerun the Lab setup.

The Puppet-install script allows to specify location, resourcegroup and puppetserver name.

Before a rerun of the Azure setup, delete the dynamically allocated Azure resourcegroup "puppet" (Default) with all sub components and wait until all resources have been destroyed.

## Puppet Agent on VMware Photon OS on Raspberry Pi 4

VMware Photon OS is a minimal container host Linux optimized to run on VMware platforms but capable of running in other environments as well. See [here](https://vmware.github.io/photon/) and [here](https://github.com/dcasota/photonos-scripts).

You can find [here](https://github.com/dcasota/photonos-scripts/wiki/Configure-a-complete-Raspberry-Pi-Virtualhere-installation) a description on how to install and configure the operating system, that said, provisioned without any automation tools so far. But, instead of the Virtualhere installation part, install the puppet agent bits.

Since quite a while Puppetlabs supports Puppet agent on aarch64. Unfortunately there is no tdnf package (tiny dandified yum) version of Puppet agent on Photon OS, but you can download the rpm from https://yum.puppetlabs.com/puppet. Here's the installation recipe - it installs the rhel 7.9 puppet agent.

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

## View and manage package inventory

To get to know which packages are installed on the nodes, package inventory must be enabled. Having checked the [docs](https://puppet.com/docs/pe/2019.8/viewing_packages_in_use.html), don't forget to run the puppet task twice.

![viewingpackages](https://user-images.githubusercontent.com/14890243/178145830-41210dba-ec35-409a-881b-3ef9b754d1e1.png)

To rerun the task, go to Jobs, click on the job and push the "run again" button. After the rerun you can browse the packages catalog.

![enabledpackages](https://user-images.githubusercontent.com/14890243/178146050-f4995e21-5965-4266-9a0e-fa2f93d2382c.png)

As the RPi4 has been setuped with VMware Photon OS, you can find as provider the package manager tdnf in the provider listing as well, see [tdnf Photon OS docs](https://vmware.github.io/photon/docs/administration-guide/managing-packages-with-tdnf/).

## TLS

Photon OS and Puppet both support transport layer security level (TLS) version 1.3, see [Puppetserver release notes](https://puppet.com/docs/pe/2019.8/osp/server/release_notes.html).

Actually I'm not sure what puppet does if we specify the tls level.

There is a short intro about [where to configure the ssl protocols](https://puppet.com/docs/pe/2019.8/enable_tlsv1.html).

![tls1 3onnodes](https://user-images.githubusercontent.com/14890243/178146970-64e56bd1-a7d3-4a58-bef3-6290d7a59c52.png)

The puppet job runs successfully. On the job reports we can see what happened.

The puppetserver report shows that the sequence has changed the default from "TLSv1.3,TLSv1.2" to "TLSv1.2,TLSv1.3".

![tlsprotocols](https://user-images.githubusercontent.com/14890243/178147841-8ddcba0d-8a80-4ac6-8047-499a2d47c0e7.png)

Hence, to ensure the sequence "TLSv1.3,TLSv1.2" on puppetserver, nothing has to be done. 

As expected, on the photon node this is not the case.

![tlsprotocolsphoton](https://user-images.githubusercontent.com/14890243/178147846-c72497af-357a-4200-80fb-056476bbd133.png)

So, how to enforce TLS sequence on the node as well? (to be continued)


# Lab findings

## Setup

The lab setup is pretty straightforward. Some considerations for a next, more advanced setup could be:
- Add Puppet ci/cd examples
- Azure Networking: eg. Azure Private Cloud with restricted VNET and RPI4 VPN connectivity, cloud image rework for Azure GenV2 to support secureboot+tpm, etc.
- Azure Monitoring: Longterm workload considerations for Puppetserver, eg. justification for vm size Standard_A4_v2, additional disk.
- Azure&Puppet Troubleshoot knowledge, considering availability + scaling

## Puppet
Facing the findings so far, the user interface of Puppet Enterprise is somewhat helpful for starters.

Eg. you can add a local user and send the password reset link to the user.
Admins know the situation when a ssh connection has remained open for hours. Puppetmaster has a time restriction on ssh sessions per default.
Node jobs reports, events, and account activities are clear and tidy. It's easy to find intentional changes.
Also, the docs give a good first impression about the installation steps.

There are also a few, ui-related disappointments.
The packages view doesn't show a possibility to filter/sort provider name or instances, but it can be accomplished by exporting data to excel.
The class-driven configuration management has advantages. As beginner AND following the guidelines to use the ui, hoewever it's hard to get the information about what a class does. If you declare a class to apply to nodes, there is no help text eg. when hovering over the class text.
