# Parameters Configuration Guide

This guide explains how to configure the `parameters.alz.json` file for your Azure OpenAI Chat Baseline Landing Zone deployment.

## Overview

The parameters file contains platform-specific configuration that must be updated with resources provided by your platform team. These resources should already exist in your application landing zone subscription.

## Required Parameters

### Platform Resources

#### 1. Spoke Virtual Network
```json
"existingResourceIdForSpokeVirtualNetwork": {
  "value": "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-NETWORKING-RG/providers/Microsoft.Network/virtualNetworks/YOUR-SPOKE-VNET-NAME"
}
```

**What it is:** The resource ID of your spoke virtual network provided by the platform team.

**Requirements:**
- Must be at least a `/22` CIDR block
- Must have DNS configuration set for hub-based resolution
- Must have established peering with the hub network
- Must be in the same region as your workload resources

**How to find it:**
```bash
# List virtual networks in your subscription
az network vnet list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, AddressSpace:addressSpace.addressPrefixes}" -o table

# Get the full resource ID
az network vnet show --name YOUR-VNET-NAME --resource-group YOUR-RG-NAME --query "id" -o tsv
```

#### 2. User-Defined Route (UDR) for Internet Traffic
```json
"existingResourceIdForUdrForInternetTraffic": {
  "value": "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-NETWORKING-RG/providers/Microsoft.Network/routeTables/YOUR-UDR-NAME"
}
```

**What it is:** The resource ID of the UDR that forces internet-bound traffic through a platform-provided Network Virtual Appliance (NVA).

**When to use:**
- Required if your platform team is **not** using Azure Virtual WAN
- Set to empty string `""` if using Virtual WAN-provided route tables

**How to find it:**
```bash
# List route tables in your subscription
az network route-table list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o table

# Get the full resource ID
az network route-table show --name YOUR-UDR-NAME --resource-group YOUR-RG-NAME --query "id" -o tsv
```

### Subnet Address Prefixes

All subnet address prefixes must be within your spoke virtual network's address space and must not conflict with existing subnets.

#### Address Planning Example
If your spoke VNet is `10.240.0.0/22`, you have the range `10.240.0.0` - `10.240.3.255` available (1,024 IP addresses).

#### Required Subnets

##### 1. Bastion Subnet
```json
"bastionSubnetAddressPrefix": {
  "value": "10.240.0.0/26"
}
```
- **Purpose:** For platform-managed bastion connectivity
- **Size:** `/26` provides 64 IP addresses (59 usable)
- **Usage:** Low to moderate traffic

##### 2. App Services Subnet
```json
"appServicesSubnetAddressPrefix": {
  "value": "10.240.1.0/24"
}
```
- **Purpose:** For Azure App Service hosting the chat UI
- **Size:** `/24` provides 256 IP addresses (251 usable)
- **Usage:** Delegated to App Service, requires larger subnet

##### 3. Application Gateway Subnet
```json
"appGatewaySubnetAddressPrefix": {
  "value": "10.240.2.0/24"
}
```
- **Purpose:** For Azure Application Gateway with WAF
- **Size:** `/24` provides 256 IP addresses (251 usable)
- **Usage:** Dedicated to Application Gateway instances

##### 4. Private Endpoints Subnet
```json
"privateEndpointsSubnetAddressPrefix": {
  "value": "10.240.3.0/27"
}
```
- **Purpose:** For private endpoints to Azure services (Storage, Cosmos DB, AI Search, etc.)
- **Size:** `/27` provides 32 IP addresses (27 usable)
- **Usage:** One IP per private endpoint

##### 5. Build Agents Subnet
```json
"buildAgentsSubnetAddressPrefix": {
  "value": "10.240.3.32/27"
}
```
- **Purpose:** For build agents in CI/CD pipelines
- **Size:** `/27` provides 32 IP addresses (27 usable)
- **Usage:** For automated deployment processes

##### 6. AI Agents Subnet
```json
"agentsSubnetAddressPrefix": {
  "value": "10.240.4.0/24"
}
```
- **Purpose:** For AI Foundry Agent Service egress traffic
- **Size:** `/24` provides 256 IP addresses (251 usable)
- **Usage:** Delegated subnet for AI agent compute

##### 7. Jump Box Subnet
```json
"jumpBoxSubnetAddressPrefix": {
  "value": "10.240.3.128/28"
}
```
- **Purpose:** For jump box VMs (if needed for agent deployment)
- **Size:** `/28` provides 16 IP addresses (11 usable)
- **Usage:** Minimal, only for jump box VMs

## Configuration Methods

### Method 1: Interactive Setup Script (Recommended)
Use the automated setup script:
```bash
./setup-parameters.sh
```

### Method 2: Manual Configuration

1. Copy the template:
   ```bash
   cp infra-as-code/bicep/parameters.alz.template.json infra-as-code/bicep/parameters.alz.json
   ```

2. Edit the file and replace:
   - `YOUR-SUBSCRIPTION-ID` with your actual subscription ID
   - `YOUR-NETWORKING-RG` with your networking resource group name
   - `YOUR-SPOKE-VNET-NAME` with your spoke virtual network name
   - `YOUR-UDR-NAME` with your UDR name (if applicable)
   - Update all subnet address prefixes to match your VNet's address space

### Method 3: Using Azure CLI to Generate Configuration

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get your spoke VNet resource ID (adjust names as needed)
SPOKE_VNET_ID=$(az network vnet list --query "[?contains(name, 'spoke')].id" -o tsv | head -n1)

# Get your UDR resource ID (adjust names as needed)
UDR_ID=$(az network route-table list --query "[?contains(name, 'udr') || contains(name, 'hub')].id" -o tsv | head -n1)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Spoke VNet ID: $SPOKE_VNET_ID"
echo "UDR ID: $UDR_ID"
```

## Validation

### Validate Your Configuration
```bash
# Validate the configuration (requires setup script)
./setup-parameters.sh --validate
```

### Manual Validation Commands
```bash
# Check if spoke VNet exists and is accessible
az network vnet show --ids "/subscriptions/.../virtualNetworks/your-vnet"

# Check if UDR exists and is accessible (if specified)
az network route-table show --ids "/subscriptions/.../routeTables/your-udr"

# Check subnet overlap (replace with your VNet resource ID)
az network vnet subnet list --vnet-name YOUR-VNET --resource-group YOUR-RG --query "[].{Name:name, AddressPrefix:addressPrefix}" -o table
```

## Common Issues

### Issue: Resource Not Found
**Symptoms:** Deployment fails with "resource not found" errors
**Solution:** 
- Verify resource IDs are correct and complete
- Ensure you have access to the specified resources
- Check that resources exist in the expected subscription and resource group

### Issue: Subnet Conflicts
**Symptoms:** Deployment fails with subnet overlap errors
**Solution:**
- Verify subnet ranges don't overlap with existing subnets
- Use `az network vnet subnet list` to check existing allocations
- Adjust your subnet address prefixes accordingly

### Issue: Address Space Mismatch
**Symptoms:** Subnets cannot be created within the VNet
**Solution:**
- Ensure all subnet prefixes are within the VNet's address space
- Use the VNet's address space as a guide (e.g., 10.240.0.0/22)
- Consider the VNet's available address range

## Best Practices

1. **Use Consistent Addressing:** Use sequential subnets where possible for easier management
2. **Plan for Growth:** Choose subnet sizes that accommodate future expansion
3. **Document Changes:** Keep track of any customizations you make to the parameters
4. **Test First:** Validate your configuration before running the full deployment
5. **Backup Configuration:** Keep a backup of working parameter files

## Next Steps

After configuring your parameters file:

1. Validate the configuration: `./setup-parameters.sh --validate`
2. Run the deployment: `./deploy-complete-enhanced.sh`
3. Monitor the deployment progress in the Azure portal
4. Follow the post-deployment steps in the main README
