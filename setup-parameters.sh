#!/bin/bash

# Azure OpenAI Chat Baseline Landing Zone - Interactive Setup Script
# This script helps configure the parameters.alz.json file interactively

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

# Function to prompt user for input with validation
prompt_input() {
    local prompt_text="$1"
    local validation_regex="$2"
    local error_msg="$3"
    local default_value="$4"
    local user_input
    
    while true; do
        if [ -n "$default_value" ]; then
            read -p "$prompt_text [$default_value]: " user_input
            user_input=${user_input:-$default_value}
        else
            read -p "$prompt_text: " user_input
        fi
        
        if [[ -z "$validation_regex" ]] || [[ "$user_input" =~ $validation_regex ]]; then
            echo "$user_input"
            break
        else
            print_error "$error_msg"
        fi
    done
}

# Function to validate subscription access
validate_subscription() {
    local subscription_id="$1"
    
    print_status "Validating subscription access: $subscription_id"
    
    if az account show --subscription "$subscription_id" &> /dev/null; then
        print_success "Subscription access validated"
        return 0
    else
        print_error "Cannot access subscription: $subscription_id"
        return 1
    fi
}

# Function to validate resource existence
validate_resource() {
    local resource_id="$1"
    local resource_type="$2"
    
    print_status "Validating $resource_type exists: $resource_id"
    
    case "$resource_type" in
        "vnet")
            if az network vnet show --ids "$resource_id" &> /dev/null; then
                print_success "Virtual Network validated"
                return 0
            fi
            ;;
        "route-table")
            if az network route-table show --ids "$resource_id" &> /dev/null; then
                print_success "Route Table validated"
                return 0
            fi
            ;;
    esac
    
    print_error "$resource_type not found: $resource_id"
    return 1
}

# Function to suggest address prefixes based on VNet
suggest_address_prefixes() {
    local vnet_id="$1"
    
    print_status "Analyzing virtual network address space..."
    
    local address_prefixes=$(az network vnet show --ids "$vnet_id" --query "addressSpace.addressPrefixes" -o json 2>/dev/null || echo "[]")
    
    if [ "$address_prefixes" != "[]" ]; then
        print_status "Available address prefixes in the VNet:"
        echo "$address_prefixes" | jq -r '.[]' | sed 's/^/  - /'
        echo ""
        print_warning "Please ensure your subnet prefixes fall within these ranges and don't conflict with existing subnets."
    fi
}

# Function to create backup of existing parameters file
backup_parameters_file() {
    local params_file="./infra-as-code/bicep/parameters.alz.json"
    local backup_file="./infra-as-code/bicep/parameters.alz.json.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$params_file" ]; then
        cp "$params_file" "$backup_file"
        print_success "Backup created: $backup_file"
    fi
}

# Function to update parameters file
update_parameters_file() {
    local params_file="./infra-as-code/bicep/parameters.alz.json"
    
    # Create updated parameters file
    cat > "$params_file" << EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "existingResourceIdForSpokeVirtualNetwork": {
      "value": "$SPOKE_VNET_ID"
    },
    "existingResourceIdForUdrForInternetTraffic": {
      "value": "$UDR_ID"
    },
    "bastionSubnetAddressPrefix": {
      "value": "$BASTION_SUBNET_PREFIX"
    },
    "appServicesSubnetAddressPrefix": {
      "value": "$APPSERVICES_SUBNET_PREFIX"
    },
    "appGatewaySubnetAddressPrefix": {
      "value": "$APPGATEWAY_SUBNET_PREFIX"
    },
    "privateEndpointsSubnetAddressPrefix": {
      "value": "$PRIVATEENDPOINTS_SUBNET_PREFIX"
    },
    "buildAgentsSubnetAddressPrefix": {
      "value": "$BUILDAGENTS_SUBNET_PREFIX"
    },
    "agentsSubnetAddressPrefix": {
      "value": "$AGENTS_SUBNET_PREFIX"
    },
    "jumpBoxSubnetAddressPrefix": {
      "value": "$JUMPBOX_SUBNET_PREFIX"
    }
  }
}
EOF
    
    print_success "Parameters file updated: $params_file"
}

# Main configuration function
configure_parameters() {
    print_header "CONFIGURING PARAMETERS FOR LANDING ZONE DEPLOYMENT"
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install jq to use this script."
        print_status "On Ubuntu/Debian: sudo apt-get install jq"
        print_status "On macOS: brew install jq"
        exit 1
    fi
    
    # Ensure user is logged into Azure CLI
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    # Get current subscription info
    local current_sub=$(az account show --query "{id:id, name:name}" -o json)
    local current_sub_id=$(echo "$current_sub" | jq -r '.id')
    local current_sub_name=$(echo "$current_sub" | jq -r '.name')
    
    print_status "Current subscription: $current_sub_name ($current_sub_id)"
    
    if [[ $(prompt_input "Use this subscription? (y/n)" "^[yYnN]$" "Please enter y or n") =~ [nN] ]]; then
        print_status "Available subscriptions:"
        az account list --query "[].{name:name, id:id}" -o table
        local subscription_id=$(prompt_input "Enter subscription ID" "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$" "Please enter a valid subscription ID")
        az account set --subscription "$subscription_id"
        validate_subscription "$subscription_id"
    fi
    
    # Configure spoke virtual network
    print_header "SPOKE VIRTUAL NETWORK CONFIGURATION"
    print_status "This should be the virtual network provided by your platform team in your application landing zone."
    
    SPOKE_VNET_ID=$(prompt_input "Enter the resource ID of your spoke virtual network" "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$" "Please enter a valid virtual network resource ID")
    
    if ! validate_resource "$SPOKE_VNET_ID" "vnet"; then
        print_error "Virtual network validation failed. Please check the resource ID and your permissions."
        exit 1
    fi
    
    suggest_address_prefixes "$SPOKE_VNET_ID"
    
    # Configure UDR
    print_header "USER-DEFINED ROUTE (UDR) CONFIGURATION"
    print_status "This should be the UDR provided by your platform team for internet traffic routing."
    print_status "Leave empty if your platform team is using Azure Virtual WAN instead."
    
    UDR_ID=$(prompt_input "Enter the resource ID of your UDR (or press Enter to skip)" "" "" "")
    
    if [ -n "$UDR_ID" ]; then
        if [[ ! "$UDR_ID" =~ ^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/routeTables/[^/]+$ ]]; then
            print_error "Invalid UDR resource ID format."
            exit 1
        fi
        
        if ! validate_resource "$UDR_ID" "route-table"; then
            print_error "Route table validation failed. Please check the resource ID and your permissions."
            exit 1
        fi
    fi
    
    # Configure subnet address prefixes
    print_header "SUBNET ADDRESS PREFIX CONFIGURATION"
    print_status "Configure address prefixes for each subnet. These must be within your spoke VNet's address space."
    print_warning "Ensure these ranges don't conflict with existing subnets."
    
    # Default suggestions based on common patterns
    local default_base="10.240"  # Common spoke network range
    
    print_status "Configuring subnets (use CIDR notation like 10.240.1.0/24):"
    
    BASTION_SUBNET_PREFIX=$(prompt_input "Bastion subnet address prefix" "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$" "Please enter a valid CIDR range" "${default_base}.0.0/26")
    
    APPSERVICES_SUBNET_PREFIX=$(prompt_input "App Services subnet address prefix" "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$" "Please enter a valid CIDR range" "${default_base}.1.0/24")
    
    APPGATEWAY_SUBNET_PREFIX=$(prompt_input "Application Gateway subnet address prefix" "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$" "Please enter a valid CIDR range" "${default_base}.2.0/24")
    
    PRIVATEENDPOINTS_SUBNET_PREFIX=$(prompt_input "Private Endpoints subnet address prefix" "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$" "Please enter a valid CIDR range" "${default_base}.3.0/27")
    
    BUILDAGENTS_SUBNET_PREFIX=$(prompt_input "Build Agents subnet address prefix" "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$" "Please enter a valid CIDR range" "${default_base}.3.32/27")
    
    AGENTS_SUBNET_PREFIX=$(prompt_input "AI Agents subnet address prefix" "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$" "Please enter a valid CIDR range" "${default_base}.4.0/24")
    
    JUMPBOX_SUBNET_PREFIX=$(prompt_input "Jump Box subnet address prefix" "^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$" "Please enter a valid CIDR range" "${default_base}.3.128/28")
    
    # Summary
    print_header "CONFIGURATION SUMMARY"
    echo "Spoke Virtual Network: $SPOKE_VNET_ID"
    echo "UDR for Internet Traffic: ${UDR_ID:-"Not specified (using VWAN)"}"
    echo ""
    echo "Subnet Configurations:"
    echo "  - Bastion: $BASTION_SUBNET_PREFIX"
    echo "  - App Services: $APPSERVICES_SUBNET_PREFIX"
    echo "  - Application Gateway: $APPGATEWAY_SUBNET_PREFIX"
    echo "  - Private Endpoints: $PRIVATEENDPOINTS_SUBNET_PREFIX"
    echo "  - Build Agents: $BUILDAGENTS_SUBNET_PREFIX"
    echo "  - AI Agents: $AGENTS_SUBNET_PREFIX"
    echo "  - Jump Box: $JUMPBOX_SUBNET_PREFIX"
    
    if [[ $(prompt_input "Continue with this configuration? (y/n)" "^[yYnN]$" "Please enter y or n") =~ [nN] ]]; then
        print_status "Configuration cancelled."
        exit 0
    fi
    
    # Create backup and update parameters file
    backup_parameters_file
    update_parameters_file
    
    print_success "✅ Configuration completed successfully!"
    print_status "The parameters.alz.json file has been updated with your configuration."
    print_status "You can now run the deployment script: ./deploy-complete-enhanced.sh"
}

# Function to validate existing configuration
validate_existing_config() {
    print_header "VALIDATING EXISTING CONFIGURATION"
    
    local params_file="./infra-as-code/bicep/parameters.alz.json"
    
    if [ ! -f "$params_file" ]; then
        print_error "Parameters file not found: $params_file"
        return 1
    fi
    
    local spoke_vnet_id=$(jq -r '.parameters.existingResourceIdForSpokeVirtualNetwork.value' "$params_file")
    local udr_id=$(jq -r '.parameters.existingResourceIdForUdrForInternetTraffic.value' "$params_file")
    
    # Check for placeholder values
    if [[ "$spoke_vnet_id" == *"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"* ]]; then
        print_error "Spoke VNet resource ID contains placeholder values. Please run configuration."
        return 1
    fi
    
    if [[ "$udr_id" != "null" ]] && [[ "$udr_id" == *"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"* ]]; then
        print_error "UDR resource ID contains placeholder values. Please run configuration."
        return 1
    fi
    
    # Validate resources exist
    if ! validate_resource "$spoke_vnet_id" "vnet"; then
        return 1
    fi
    
    if [[ "$udr_id" != "null" ]] && [[ "$udr_id" != "" ]]; then
        if ! validate_resource "$udr_id" "route-table"; then
            return 1
        fi
    fi
    
    print_success "Existing configuration is valid!"
    return 0
}

# Help function
show_help() {
    echo "Azure OpenAI Chat Baseline Landing Zone - Interactive Setup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -v, --validate  Validate existing configuration without making changes"
    echo "  -c, --configure Interactive configuration (default)"
    echo ""
    echo "This script helps you configure the parameters.alz.json file with:"
    echo "  - Spoke virtual network resource ID"
    echo "  - UDR resource ID (if not using VWAN)"
    echo "  - Subnet address prefixes for all required subnets"
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed and logged in"
    echo "  - jq installed for JSON processing"
    echo "  - Access to your application landing zone subscription"
    echo "  - Platform resources (spoke VNet, UDR) already provisioned"
}

# Main execution based on arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--validate)
        validate_existing_config
        exit $?
        ;;
    -c|--configure|"")
        configure_parameters
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
