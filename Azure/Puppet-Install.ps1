#
# Deploy a Puppet Enterprise Azure cloud image
#
# History
# 0.1  05.07.2022   dcasota  Initial release
# 0.2  09.07.2022   dcasota  bugfix windowsConfiguration, minor optimizations, see anomaly
# 0.21 10.07.2022   dcasota  fix securityrules

# Web links
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage
# https://puppet.com/misc/version-history
# https://puppet.com/products/puppet-enterprise/product-support-lifecycle

[CmdletBinding()]
param(
[Parameter(Mandatory = $true)][ValidateNotNull()]
[ValidateSet('eastasia','southeastasia','centralus','eastus','eastus2','westus','northcentralus','southcentralus',`
'northeurope','westeurope','japanwest','japaneast','brazilsouth','australiaeast','australiasoutheast',`
'southindia','centralindia','westindia','canadacentral','canadaeast','uksouth','ukwest','westcentralus','westus2',`
'koreacentral','koreasouth','francecentral','francesouth','australiacentral','australiacentral2',`
'uaecentral','uaenorth','southafricanorth','southafricawest','switzerlandnorth','switzerlandwest',`
'germanynorth','germanywestcentral','norwaywest','norwayeast','brazilsoutheast','westus3')]
[string]$LocationName="switzerlandnorth",

[Parameter(Mandatory = $true)][ValidateNotNull()]
[string]$ResourceGroupName="puppet",

[Parameter(Mandatory = $true)][ValidateNotNull()]
[string]$VMName = "puppet",

[Parameter(Mandatory = $false)][ValidateNotNull()]
[string]$ComputerName = $VMName,

[Parameter(Mandatory = $false)]
[string]$RuntimeId = (Get-Random).ToString(),

[Parameter(Mandatory = $false)][ValidateLength(3,24)][ValidatePattern("[a-z0-9]")]
[string]$StorageAccountName=("${Computername}${RuntimeId}").ToLower(),

[Parameter(Mandatory = $false)][ValidateNotNull()]
[string]$NetworkName = "${Computername}${RuntimeId}vnet",

[Parameter(Mandatory = $false)][ValidateNotNull()]
[string]$SubnetAddressPrefix = "192.168.1.0/24",

[Parameter(Mandatory = $false)][ValidateNotNull()]
[string]$VnetAddressPrefix = "192.168.0.0/16",

[Parameter(Mandatory = $false)][ValidateNotNull()]
[string]$VMSize = "Standard_A4_v2",

[Parameter(Mandatory = $false)][ValidateNotNull()]
[string]$NICName = "${ComputerName}${RuntimeId}nic",

[Parameter(Mandatory = $false)]
[string]$PublicIPDNSName="${ComputerName}${RuntimeId}dns",

[Parameter(Mandatory = $false)]
[string]$nsgName = "${ComputerName}${RuntimeId}nsg",

[Parameter(Mandatory = $false)]
[string]$VMLocalAdminUser = "localadmin",

[Parameter(Mandatory = $false)][ValidateLength(12,123)]
[string]$VMLocalAdminPwd="ShouldNotBe123!" #12-123 chars

)

# cloud image specs
$publisherName = "Puppet"
$offerName = "puppet-enterprise-201818"
$skuName = "pe_2019_8_11"
$version="2019.8.11"

# check Azure Powershell
# https://github.com/Azure/azure-powershell/issues/13530
# https://github.com/Azure/azure-powershell/issues/13337
$check=get-module -ListAvailable | where-object {$_ -ilike 'Az.*'}
if ([Object]::ReferenceEquals($check,$null))
{
    write-host "Please install Azure Powershell."
    break
}

$azconnect=get-azcontext -ErrorAction SilentlyContinue
if ([Object]::ReferenceEquals($azconnect,$null))
{
    $azconnect=connect-azaccount -devicecode
}


if (!(Get-variable -name azconnect -ErrorAction SilentlyContinue))
{
    write-host "Azure Powershell login required."
    break
}


#Set the context to the subscription Id where Managed Disk exists and where virtual machine will be created if necessary
$subscriptionId=(get-azcontext).Subscription.Id
# set subscription
select-AzSubscription -Subscription $subscriptionId

# Verify virtual machine doesn't exist
[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction SilentlyContinue
if ($VM)
{
	write-host "VM $VMName already exists."
	break
}

# create lab resource group if it does not exist
$result = get-azresourcegroup -name $ResourceGroupName -Location $LocationName -ErrorAction SilentlyContinue
if (([string]::IsNullOrEmpty($result)))
{
    New-AzResourceGroup -Name $ResourceGroupName -Location $LocationName
}

# storageaccount
$storageaccount=get-azstorageaccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
if ( -not $($storageaccount))
{
	$storageaccount=New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $LocationName -Kind Storage -SkuName Standard_LRS -ErrorAction SilentlyContinue
	if ( -not $($storageaccount))
    {
        write-host "Storage account has not been created. Check if the name is already taken."
        break
    }
}
do {sleep -Milliseconds 1000} until ($((get-azstorageaccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).ProvisioningState) -ieq "Succeeded") 
$storageaccountkey=(get-azstorageaccountkey -ResourceGroupName $ResourceGroupName -name $StorageAccountName)
$storageaccount=get-azstorageaccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue


# networksecurityruleconfig
$nsg=get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (([string]::IsNullOrEmpty($nsg)))
{
    $nsgRule1 = New-AzNetworkSecurityRuleConfig -Name mynsgRule1 -Description "Allow SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22
    $nsgRule2 = New-AzNetworkSecurityRuleConfig -Name mynsgRule2 -Description "Allow 443" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 443
    $nsgRule3 = New-AzNetworkSecurityRuleConfig -Name mynsgRule3 -Description "Allow 8140 tcp" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 130 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 8140
    $nsgRule4 = New-AzNetworkSecurityRuleConfig -Name mynsgRule4 -Description "Allow 8142 tcp" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 140 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 8142
    $nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ResourceGroupName -Location $LocationName -SecurityRules $nsgRule1,$nsgRule2,$nsgRule3,$nsgRule4

}


$vnet = get-azvirtualnetwork -name $networkname -ResourceGroupName $resourcegroupname -ErrorAction SilentlyContinue
if (([string]::IsNullOrEmpty($vnet)))
{
    $SingleSubnet  = New-AzVirtualNetworkSubnetConfig -Name frontendSubnet -AddressPrefix $SubnetAddressPrefix
    $vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
    $vnet | Set-AzVirtualNetwork
}

# Create a public IP address
$nic=get-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (([string]::IsNullOrEmpty($nic)))
{
    $pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $LocationName -Name $PublicIPDNSName -AllocationMethod Static -IdleTimeoutInMinutes 4
    # Create a virtual network card and associate with public IP address and NSG
    $nic = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName `
        -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
}

# VM local admin setting
$VMLocalAdminSecurePassword = ConvertTo-SecureString $VMLocalAdminPwd -AsPlainText -Force
$LocalAdminUserCredential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword)


$vmConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize | Add-AzVMNetworkInterface -Id $nic.Id
if (!(([string]::IsNullOrEmpty($vmConfig))))
{
        # Create a virtual machine configuration
		$vmimage= get-azvmimage -Location $LocationName -PublisherName $PublisherName -Offer $offerName -Skus $skuname -Version $version
		if (-not ([Object]::ReferenceEquals($vmimage,$null)))
		{
			if (-not ([Object]::ReferenceEquals($vmimage.PurchasePlan,$null)))
			{

                # Anomaly: The publishername published from set-azmarketplaceterms is not Puppet!
                write-output "Publishername = $publisherName"
                write-output "Offername = $offerName"

                # marketplace plan
                # be aware first the marketplace terms must be accepted manually. https://github.com/terraform-providers/terraform-provider-azurerm/issues/1145#issuecomment-383070349
				$agreementTerms=Get-AzMarketplaceterms -publisher $vmimage.PurchasePlan.publisher -Product $vmimage.PurchasePlan.product -name $vmimage.PurchasePlan.name
				Set-AzMarketplaceTerms -publisher $vmimage.PurchasePlan.publisher -Product $vmimage.PurchasePlan.product -name $vmimage.PurchasePlan.name -Terms $agreementTerms -Accept
				$agreementTerms=Get-AzMarketplaceterms -publisher $vmimage.PurchasePlan.publisher -Product $vmimage.PurchasePlan.product -name $vmimage.PurchasePlan.name
				Set-AzMarketplaceTerms -publisher $vmimage.PurchasePlan.publisher -Product $vmimage.PurchasePlan.product -name $vmimage.PurchasePlan.name -Terms $agreementTerms -Accept
				$vmConfig = Set-AzVMPlan -VM $vmConfig -publisher $vmimage.PurchasePlan.publisher -Product $vmimage.PurchasePlan.product -name $vmimage.PurchasePlan.name
			}

			$vmConfig = Set-AzVMOperatingSystem -Linux -VM $vmConfig -ComputerName $ComputerName -Credential $LocalAdminUserCredential | `
			Set-AzVMSourceImage -PublisherName $PublisherName -Offer $offerName -Skus $skuname -Version $version
            $vmConfig | Set-AzVMBootDiagnostic -Disable

            # Create the VM
            New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $vmConfig

            $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
            if (!(([string]::IsNullOrEmpty($VM))))
            {
                Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
            }
		}
}
