# Introduction
Puppet is a open source software configuration management and deployment tool. It solves system administrators' problems working with multiple servers by automating the IT infrastructure, and ensuring that all systems are configured to a desired and predictable state. Puppet is written in Ruby, a highly objectoriented programming language.

Lately, in 2022 the company Puppetlabs has been acquired by Perforce - a leading provider of highly scalable development and DevOps solutions.
The goal of a new tools for Kubernetes and cloud native apps resulted already in a market consolidation of independent configuration management vendors , eg. Chef has been Acquired by Progress, Ansible has been bought by IBM, and Saltstack has been bought by VMware in 2020.  The focus on making data center and cloud infrastructure easily consumable and facing the multi-cloud adoption challenges, the competitor Hashicorp gained between 2015 until 2022 more traction with their products Terraform, Packer, Vault, etc. than Puppet did before. Today the Puppet community embraced the Hashicorp tools at forge.puppet.com.

I had an interesting talk to Roger Widmer, IT infrastructure expert at MeteoSwiss. He convinced me to get familiar with puppet. MeteoSwiss produces climate information. Engineers do environmental science (environmental and climate change modeling, glacier studies, urban hydrological modeling, meteorological studies) and for their work baremetal performance cpu/gpu/storage/ram is critical.

Here some related weather observations weblinks:  
- COSMO, Consortium for small scale modeling: https://www.cosmo-model.org/content/support/software/default.htm
- Snowmelt modeling: https://wiki.c2sm.ethz.ch/pub/MODELS/COSMOCuW2019/3_COSMO_User_Workshop_19_TJonas.pdf
- MeteoSwiss Payerne Atmospheric Observatory: http://srnwp.cosmo-model.org/archive/Payerne/support/metadata.pdf
- COSMO Transition to ICON, C2I : https://www.cosmo-model.org/content/support/icon/default.htm, https://www.cosmo-model.org/content/consortium/generalMeetings/general2021/parallel/wg6-c2i/C2I_COSMO-GM_Introduction.pdf
- NinJo Meteorological Workstation: [http://www.ninjo-workstation.com/](http://www.ninjo-workstation.com/project-members.0.html)
- Abstractions for Weather and Climate Models: https://pasc17.pasc-conference.org/fileadmin/user_upload/pasc17/program/MS21.pdf

Roger explained that the puppet enterprise platform powers all MeteoSwiss weather observations related workstations and server farms. For the planned datacenter projects - new geolocation and adoption to multi-cloud, business continuity management is a main topic. 

# Jumpstart with Puppet Enterprise cloud images
Puppetlabs offers Puppet Enterprise (PE) as cloud image for a standard installation available from the [AWS Marketplace](https://aws.amazon.com/marketplace/pp/prodview-df2wt3ipoydbe), [Microsoft Azure Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/puppet.puppet-enterprise-201818) and for the [Oracle Cloud Marketplace](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/101747862), see the [hardware requirements for cloud deployments](https://puppet.com/docs/pe/2019.8/hardware_requirements.html#hardware_requirements_cloud). For VMware datacenters, vRealize Automation offers a [Puppet Enterprise Integration](https://docs.vmware.com/de/vRealize-Automation/8.8/Using-and-Managing-Cloud-Assembly/GUID-EDEEE4C7-8EEB-424F-8DC1-E9F8CCE1F27B.html) as well.

# Documentation
[Manual Puppet Enterprise 2019.8.11](https://github.com/dcasota/puppetlabs-scripts/files/9077405/pe.pdf)


# Azure Lab installation
For a first lab environment, I will use an onprem RPi4, a laptop connected to the internet and an Azure puppetserver.

Before going to interconnect the Azure cloud environment, let's start with provisioning the puppetserver cloud image.

On the Azure marketplace, the latest available cloud image is pe2019.8.11. The following script provisions the vm.

./Puppet-Install.ps1 -ResourceGroupName <your resource group> -Location <your location> -VMName <your name puppetserver>

Prerequisites are:
- Script must run on MS Windows OS with Powershell PSVersion 5.1 or higher
- Azure account with Virtual Machine contributor role

It may take a while until puppetserver is up and running. Meanwhile connect with ssh using the localadmin credentials, and run ```sudo /opt/puppetlabs/cloud/bin/check_status.sh --wait```. Wait until the configuration process has finished.  

![pe-services](https://user-images.githubusercontent.com/14890243/178111433-82c9e342-8c4b-4926-af9a-e101c3f5a353.png)

In the docs it is written that you can set the console_password with ```sudo /opt/puppetlabs/puppet/bin/puppet infrastructure console_password --password=<yourpassword>```. You must be logged-in as root to run the command - obviously without sudo then, see https://tickets.puppetlabs.com/browse/ENTERPRISE-1352.

![pepasswordchange](https://user-images.githubusercontent.com/14890243/178112489-c9b19806-713e-448d-85a3-8eca702951fc.png)

Now login on the console.  

<img src="https://user-images.githubusercontent.com/14890243/178112692-1f42c432-d784-4e61-bc94-72af1f479ce6.png" align="left" height="300" width="210" />
<br clear="left"/><br clear="both"/>

The console appears.

![peloggedin](https://user-images.githubusercontent.com/14890243/178112702-7e423664-2131-4b8c-8512-26ea77222ad9.png)




