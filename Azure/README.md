
# Pupptserver Cloud image
Before going to interconnect the Azure cloud environment, let's start with provisioning the puppetserver cloud image.

On the Azure marketplace, the latest available cloud image is pe2019.8.11. The following script [Puppet-Install.ps1](https://github.com/dcasota/puppetlabs-scripts/blob/main/Azure/Puppet-Install.ps1) provisions the vm.

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




