#!/bin/bash

# Azure OpenAI Chat Baseline Landing Zone - Complete Turn-Key Deployment
# This script supports multiple deployment scenarios:
# 1. Single-Subscription Demo: Everything in one subscription (basic demo)
# 2. Multi-Subscription Demo: Realistic hub-spoke across subscriptions
# 3. True ALZ: Use existing platform resources

set -e

# Set default environment variables if not already set
if [ -z "${BASE_NAME:-}" ]; then
    export BASE_NAME="demo01"
    BASE_NAME_SOURCE="default"
else
    BASE_NAME_SOURCE="user-provided"
fi

if [ -z "${LOCATION:-}" ]; then
    export LOCATION="eastus2"
    LOCATION_SOURCE="default"
else
    LOCATION_SOURCE="user-provided"
fi

if [ -z "${DOMAIN_NAME_APPSERV:-}" ]; then
    export DOMAIN_NAME_APPSERV="contoso.com"
    DOMAIN_SOURCE="default"
else
    DOMAIN_SOURCE="user-provided"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

print_choice() {
    echo -e "${CYAN}$1${NC}"
}

# Function to prompt user for deployment mode
choose_deployment_mode() {
    print_header "AZURE AI FOUNDRY CHAT DEPLOYMENT OPTIONS"
    
    echo ""
    print_choice "Choose your deployment scenario:"
    print_choice "1. 🧪 Single-Subscription Demo"
    print_choice "   └─ Everything in one subscription (simplest)"
    print_choice "   └─ Good for: Learning, quick demos, development"
    print_choice "   └─ NOT suitable for production"
    echo ""
    print_choice "2. 🏢 Multi-Subscription Demo"  
    print_choice "   └─ Realistic hub-spoke across subscriptions"
    print_choice "   └─ Good for: Testing real ALZ patterns, POCs"
    print_choice "   └─ More realistic than single-subscription"
    echo ""
    print_choice "3. 🎯 True Application Landing Zone"
    print_choice "   └─ Use existing platform-provided resources"
    print_choice "   └─ Good for: Production deployments"
    print_choice "   └─ Requires pre-existing spoke VNet and UDR"
    echo ""
    
    while true; do
        read -p "Enter your choice (1, 2, or 3): " choice
        case $choice in
            1)
                export DEPLOYMENT_MODE="single-subscription"
                print_success "Selected: Single-Subscription Demo"
                break
                ;;
            2)
                export DEPLOYMENT_MODE="multi-subscription"
                print_success "Selected: Multi-Subscription Demo"
                break
                ;;
            3)
                export DEPLOYMENT_MODE="true-alz"
                print_success "Selected: True Application Landing Zone"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

# Function to get multi-subscription configuration
configure_multi_subscription() {
    print_header "MULTI-SUBSCRIPTION CONFIGURATION"
    
    print_status "This mode will create:"
    print_status "- Hub resources in a 'Platform/Connectivity' subscription"
    print_status "- Application resources in a separate 'Application' subscription"
    echo ""
    
    # Get platform subscription
    if [ -z "${PLATFORM_SUBSCRIPTION_ID:-}" ]; then
        echo "Available subscriptions:"
        az account list --query "[].{Name:name, SubscriptionId:id, State:state}" -o table
        echo ""
        read -p "Enter Platform/Connectivity Subscription ID: " PLATFORM_SUBSCRIPTION_ID
        export PLATFORM_SUBSCRIPTION_ID
    fi
    
    # Get application subscription
    if [ -z "${APPLICATION_SUBSCRIPTION_ID:-}" ]; then
        read -p "Enter Application Subscription ID: " APPLICATION_SUBSCRIPTION_ID
        export APPLICATION_SUBSCRIPTION_ID
    fi
    
    print_success "Platform Subscription: $PLATFORM_SUBSCRIPTION_ID"
    print_success "Application Subscription: $APPLICATION_SUBSCRIPTION_ID"
    
    # Validate subscriptions
    print_status "Validating subscription access..."
    
    if ! az account show --subscription "$PLATFORM_SUBSCRIPTION_ID" &> /dev/null; then
        print_error "Cannot access Platform subscription: $PLATFORM_SUBSCRIPTION_ID"
        exit 1
    fi
    
    if ! az account show --subscription "$APPLICATION_SUBSCRIPTION_ID" &> /dev/null; then
        print_error "Cannot access Application subscription: $APPLICATION_SUBSCRIPTION_ID"
        exit 1
    fi
    
    print_success "Both subscriptions are accessible"
}

# Function to create single-subscription demo resources
create_single_subscription_demo() {
    print_header "CREATING SINGLE-SUBSCRIPTION DEMO RESOURCES"
    
    print_warning "Creating all resources in current subscription"
    print_warning "This is for demo/development only - NOT suitable for production!"
    
    local current_subscription=$(az account show --query id -o tsv)
    
    # Set demo resource names
    export DEMO_PLATFORM_RG="rg-demo-platform-${BASE_NAME}"
    export DEMO_SPOKE_VNET_NAME="vnet-demo-spoke-${BASE_NAME}"
    export DEMO_HUB_VNET_NAME="vnet-demo-hub-${BASE_NAME}"
    export DEMO_UDR_NAME="udr-demo-to-hub-${BASE_NAME}"
    
    print_status "Creating platform resource group: $DEMO_PLATFORM_RG"
    az group create -l "$LOCATION" -n "$DEMO_PLATFORM_RG"
    
    print_status "Creating hub virtual network (simulated)..."
    az network vnet create \
        --resource-group "$DEMO_PLATFORM_RG" \
        --name "$DEMO_HUB_VNET_NAME" \
        --address-prefix "10.0.0.0/16" \
        --location "$LOCATION"
    
    # Create AzureFirewallSubnet for hub
    az network vnet subnet create \
        --resource-group "$DEMO_PLATFORM_RG" \
        --vnet-name "$DEMO_HUB_VNET_NAME" \
        --name "AzureFirewallSubnet" \
        --address-prefixes "10.0.1.0/26"
    
    print_status "Creating spoke virtual network: $DEMO_SPOKE_VNET_NAME"
    az network vnet create \
        --resource-group "$DEMO_PLATFORM_RG" \
        --name "$DEMO_SPOKE_VNET_NAME" \
        --address-prefix "192.168.0.0/22" \
        --location "$LOCATION"
    
    print_status "Creating user-defined route table: $DEMO_UDR_NAME"
    az network route-table create \
        --resource-group "$DEMO_PLATFORM_RG" \
        --name "$DEMO_UDR_NAME" \
        --location "$LOCATION"
    
    # Add a default route to simulate hub routing
    az network route-table route create \
        --resource-group "$DEMO_PLATFORM_RG" \
        --route-table-name "$DEMO_UDR_NAME" \
        --name "DefaultRoute" \
        --address-prefix "0.0.0.0/0" \
        --next-hop-type "VirtualAppliance" \
        --next-hop-ip-address "10.0.1.4"
    
    print_status "Creating VNet peering (hub to spoke)..."
    az network vnet peering create \
        --resource-group "$DEMO_PLATFORM_RG" \
        --name "hub-to-spoke" \
        --vnet-name "$DEMO_HUB_VNET_NAME" \
        --remote-vnet "$DEMO_SPOKE_VNET_NAME" \
        --allow-vnet-access \
        --allow-forwarded-traffic \
        --allow-gateway-transit
    
    print_status "Creating VNet peering (spoke to hub)..."
    az network vnet peering create \
        --resource-group "$DEMO_PLATFORM_RG" \
        --name "spoke-to-hub" \
        --vnet-name "$DEMO_SPOKE_VNET_NAME" \
        --remote-vnet "$DEMO_HUB_VNET_NAME" \
        --allow-vnet-access \
        --allow-forwarded-traffic \
        --use-remote-gateways false
    
    # Get resource IDs for parameters
    export SPOKE_VNET_ID="/subscriptions/$current_subscription/resourceGroups/$DEMO_PLATFORM_RG/providers/Microsoft.Network/virtualNetworks/$DEMO_SPOKE_VNET_NAME"
    export UDR_ID="/subscriptions/$current_subscription/resourceGroups/$DEMO_PLATFORM_RG/providers/Microsoft.Network/routeTables/$DEMO_UDR_NAME"
    
    print_success "Single-subscription demo resources created successfully"
}

# Function to create multi-subscription demo resources  
create_multi_subscription_demo() {
    print_header "CREATING MULTI-SUBSCRIPTION DEMO RESOURCES"
    
    print_warning "Creating realistic hub-spoke across subscriptions"
    print_status "Platform resources → Connectivity subscription"
    print_status "Application resources → Application subscription"
    
    # Deploy to Platform/Connectivity Subscription
    print_status "Switching to Platform subscription: $PLATFORM_SUBSCRIPTION_ID"
    az account set --subscription "$PLATFORM_SUBSCRIPTION_ID"
    
    local hub_base_name="corp$(echo $BASE_NAME | tail -c 3)"
    export HUB_PLATFORM_RG="rg-${hub_base_name}-hub-networking"
    export HUB_DNS_RG="rg-${hub_base_name}-dns"  
    export HUB_VNET_NAME="vnet-${hub_base_name}-hub"
    export HUB_FIREWALL_NAME="fw-${hub_base_name}-hub"
    
    # Create platform resource groups
    print_status "Creating platform resource groups..."
    az group create -l "$LOCATION" -n "$HUB_PLATFORM_RG"
    az group create -l "$LOCATION" -n "$HUB_DNS_RG"
    
    # Deploy hub virtual network
    print_status "Creating hub virtual network..."
    az network vnet create \
        --resource-group "$HUB_PLATFORM_RG" \
        --name "$HUB_VNET_NAME" \
        --address-prefix "10.0.0.0/16" \
        --location "$LOCATION"
    
    # Deploy Azure Firewall subnet
    az network vnet subnet create \
        --resource-group "$HUB_PLATFORM_RG" \
        --vnet-name "$HUB_VNET_NAME" \
        --name "AzureFirewallSubnet" \
        --address-prefixes "10.0.1.0/26"
    
    # Create public IP for firewall
    print_status "Creating Azure Firewall (simulated)..."
    az network public-ip create \
        --resource-group "$HUB_PLATFORM_RG" \
        --name "pip-${HUB_FIREWALL_NAME}" \
        --location "$LOCATION" \
        --allocation-method "Static" \
        --sku "Standard"
    
    # Note: In demo, we're not creating actual Azure Firewall due to cost
    # Just simulating the IP for routing
    export FIREWALL_PRIVATE_IP="10.0.1.4"
    
    # Create centralized private DNS zones
    print_status "Creating centralized private DNS zones..."
    az network private-dns zone create \
        --resource-group "$HUB_DNS_RG" \
        --name "privatelink.vaultcore.azure.net"
    
    az network private-dns zone create \
        --resource-group "$HUB_DNS_RG" \
        --name "privatelink.blob.core.windows.net"
    
    az network private-dns zone create \
        --resource-group "$HUB_DNS_RG" \
        --name "privatelink.documents.azure.com"
    
    # Deploy to Application Subscription
    print_status "Switching to Application subscription: $APPLICATION_SUBSCRIPTION_ID"
    az account set --subscription "$APPLICATION_SUBSCRIPTION_ID"
    
    export APP_PLATFORM_RG="rg-${BASE_NAME}-networking"
    export APP_SPOKE_VNET_NAME="vnet-${BASE_NAME}-spoke"
    export APP_UDR_NAME="udr-${BASE_NAME}-to-hub"
    
    # Create application resource groups
    print_status "Creating application resource groups..."
    az group create -l "$LOCATION" -n "$APP_PLATFORM_RG"
    
    # Deploy spoke virtual network
    print_status "Creating spoke virtual network..."
    az network vnet create \
        --resource-group "$APP_PLATFORM_RG" \
        --name "$APP_SPOKE_VNET_NAME" \
        --address-prefix "192.168.0.0/22" \
        --location "$LOCATION" \
        --dns-servers "$FIREWALL_PRIVATE_IP"
    
    # Create UDR for internet traffic through hub firewall
    print_status "Creating UDR for hub routing..."
    az network route-table create \
        --resource-group "$APP_PLATFORM_RG" \
        --name "$APP_UDR_NAME" \
        --location "$LOCATION"
    
    az network route-table route create \
        --resource-group "$APP_PLATFORM_RG" \
        --route-table-name "$APP_UDR_NAME" \
        --name "DefaultRoute" \
        --address-prefix "0.0.0.0/0" \
        --next-hop-type "VirtualAppliance" \
        --next-hop-ip-address "$FIREWALL_PRIVATE_IP"
    
    # Create VNet peering (spoke to hub)
    print_status "Creating VNet peering (spoke to hub)..."
    az network vnet peering create \
        --resource-group "$APP_PLATFORM_RG" \
        --name "spoke-to-hub" \
        --vnet-name "$APP_SPOKE_VNET_NAME" \
        --remote-vnet "/subscriptions/$PLATFORM_SUBSCRIPTION_ID/resourceGroups/$HUB_PLATFORM_RG/providers/Microsoft.Network/virtualNetworks/$HUB_VNET_NAME" \
        --allow-vnet-access \
        --allow-forwarded-traffic \
        --use-remote-gateways false
    
    # Create VNet peering (hub to spoke) - switch back to platform subscription
    print_status "Creating VNet peering (hub to spoke)..."
    az account set --subscription "$PLATFORM_SUBSCRIPTION_ID"
    az network vnet peering create \
        --resource-group "$HUB_PLATFORM_RG" \
        --name "hub-to-spoke-${BASE_NAME}" \
        --vnet-name "$HUB_VNET_NAME" \
        --remote-vnet "/subscriptions/$APPLICATION_SUBSCRIPTION_ID/resourceGroups/$APP_PLATFORM_RG/providers/Microsoft.Network/virtualNetworks/$APP_SPOKE_VNET_NAME" \
        --allow-vnet-access \
        --allow-forwarded-traffic \
        --allow-gateway-transit
    
    # Switch back to application subscription for workload deployment
    az account set --subscription "$APPLICATION_SUBSCRIPTION_ID"
    
    # Set resource IDs for parameters
    export SPOKE_VNET_ID="/subscriptions/$APPLICATION_SUBSCRIPTION_ID/resourceGroups/$APP_PLATFORM_RG/providers/Microsoft.Network/virtualNetworks/$APP_SPOKE_VNET_NAME"
    export UDR_ID="/subscriptions/$APPLICATION_SUBSCRIPTION_ID/resourceGroups/$APP_PLATFORM_RG/providers/Microsoft.Network/routeTables/$APP_UDR_NAME"
    
    print_success "Multi-subscription demo resources created successfully"
    print_status "Platform resources in subscription: $PLATFORM_SUBSCRIPTION_ID"
    print_status "Application resources in subscription: $APPLICATION_SUBSCRIPTION_ID"
}

# Function to validate existing ALZ resources
validate_existing_alz() {
    print_header "VALIDATING EXISTING ALZ RESOURCES"
    
    local params_file="./infra-as-code/bicep/parameters.alz.json"
    
    if [ ! -f "$params_file" ]; then
        print_error "Parameters file not found: $params_file"
        print_status "Please run the parameter setup first:"
        print_status "./setup-parameters.sh"
        exit 1
    fi
    
    # Check for placeholder values
    local spoke_vnet_id=$(jq -r '.parameters.existingResourceIdForSpokeVirtualNetwork.value' "$params_file")
    if [[ "$spoke_vnet_id" == *"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"* ]] || [[ "$spoke_vnet_id" == *"YOUR-"* ]]; then
        print_error "Parameters file contains placeholder values"
        print_status "Please run: ./setup-parameters.sh"
        exit 1
    fi
    
    # Try to validate if the resource actually exists
    print_status "Validating spoke VNet exists: $spoke_vnet_id"
    if ! az network vnet show --ids "$spoke_vnet_id" &> /dev/null; then
        print_error "Spoke VNet not accessible: $spoke_vnet_id"
        exit 1
    fi
    
    export SPOKE_VNET_ID="$spoke_vnet_id"
    export UDR_ID=$(jq -r '.parameters.existingResourceIdForUdrForInternetTraffic.value' "$params_file")
    
    print_success "Existing ALZ resources validated successfully"
}

# Function to update parameters file
update_parameters_file() {
    print_header "UPDATING PARAMETERS FILE"
    
    local params_file="./infra-as-code/bicep/parameters.alz.json"
    
    # Create backup if file exists
    if [ -f "$params_file" ]; then
        cp "$params_file" "$params_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Created backup of existing parameters file"
    fi
    
    # Determine bastion subnet based on deployment mode
    local bastion_subnet
    if [ "$DEPLOYMENT_MODE" = "single-subscription" ]; then
        bastion_subnet="192.168.0.0/26"  # In spoke VNet for demo
    elif [ "$DEPLOYMENT_MODE" = "multi-subscription" ]; then
        bastion_subnet="10.0.2.0/26"     # In hub VNet (more realistic)
    else
        bastion_subnet="10.0.2.0/26"     # Assume hub bastion for true ALZ
    fi
    
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
      "value": "$bastion_subnet"
    },
    "appServicesSubnetAddressPrefix": {
      "value": "192.168.1.0/24"
    },
    "appGatewaySubnetAddressPrefix": {
      "value": "192.168.2.0/24"
    },
    "privateEndpointsSubnetAddressPrefix": {
      "value": "192.168.3.0/28"
    },
    "buildAgentsSubnetAddressPrefix": {
      "value": "192.168.3.16/28"
    },
    "agentsSubnetAddressPrefix": {
      "value": "192.168.3.32/27"
    },
    "jumpBoxSubnetAddressPrefix": {
      "value": "192.168.3.64/28"
    }
  }
}
EOF
    
    print_success "Parameters file updated successfully"
}

# Function to deploy the main infrastructure
deploy_main_infrastructure() {
    print_header "DEPLOYING MAIN INFRASTRUCTURE"
    
    # Check prerequisites
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        exit 1
    fi
    
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL is not installed"  
        exit 1
    fi
    
    # Set resource group name
    export RESOURCE_GROUP="rg-${BASE_NAME}-workload"
    
    print_status "Creating workload resource group: $RESOURCE_GROUP"
    az group create -l "$LOCATION" -n "$RESOURCE_GROUP"
    
    # Generate TLS certificate for Application Gateway
    print_status "Generating TLS certificate for Application Gateway..."
    if [ ! -f "appgw.crt" ] || [ ! -f "appgw.key" ] || [ ! -f "appgw.pfx" ]; then
        openssl req -x509 -newkey rsa:2048 -keyout appgw.key -out appgw.crt -days 365 -nodes \
            -subj "/C=US/ST=WA/L=Redmond/O=Contoso/OU=IT/CN=www.${DOMAIN_NAME_APPSERV}"
        openssl pkcs12 -export -out appgw.pfx -inkey appgw.key -in appgw.crt -passout pass:
        print_success "TLS certificate generated"
    else
        print_status "Using existing TLS certificate"
    fi
    
    # Deploy main infrastructure
    export CERT_DATA=$(base64 -i appgw.pfx | tr -d '\n')
    
    print_status "Starting main infrastructure deployment..."
    print_status "This will take approximately 20 minutes..."
    
    az deployment sub create \
        -f ./infra-as-code/bicep/main.bicep \
        -l "$LOCATION" \
        -n "ai-foundry-chat-prereq-lz-baseline-${BASE_NAME}" \
        -p workloadResourceGroupName="$RESOURCE_GROUP" \
        -p baseName="$BASE_NAME" \
        -p customDomainName="$DOMAIN_NAME_APPSERV" \
        -p appGatewayListenerCertificate="$CERT_DATA" \
        -p "@./infra-as-code/bicep/parameters.alz.json" \
        -p yourPrincipalId="$(az ad signed-in-user show --query id -o tsv)"
    
    print_success "Main infrastructure deployment completed!"
}

# Function to save deployment variables
save_deployment_variables() {
    print_header "SAVING DEPLOYMENT VARIABLES"
    
    cat > "deployment-vars.env" << EOF
# Deployment Variables - Generated by deploy-complete-enhanced.sh
export BASE_NAME="$BASE_NAME"
export LOCATION="$LOCATION"
export DOMAIN_NAME_APPSERV="$DOMAIN_NAME_APPSERV"
export RESOURCE_GROUP="$RESOURCE_GROUP"
export DEPLOYMENT_MODE="$DEPLOYMENT_MODE"
EOF
    
    if [ "$DEPLOYMENT_MODE" = "multi-subscription" ]; then
        cat >> "deployment-vars.env" << EOF
export PLATFORM_SUBSCRIPTION_ID="$PLATFORM_SUBSCRIPTION_ID"
export APPLICATION_SUBSCRIPTION_ID="$APPLICATION_SUBSCRIPTION_ID"
EOF
    fi
    
    print_success "Deployment variables saved to: deployment-vars.env"
    print_status "Source this file to restore variables: source deployment-vars.env"
}

# Main execution
main() {
    print_header "AZURE AI FOUNDRY CHAT BASELINE LANDING ZONE"
    print_header "Complete Turn-Key Deployment"
    
    # Interactive prompts if environment variables not set
    if [ "$BASE_NAME_SOURCE" = "default" ]; then
        read -p "Enter base name for resources (6-8 chars, default: $BASE_NAME): " input_base_name
        if [ -n "$input_base_name" ]; then
            export BASE_NAME="$input_base_name"
        fi
    fi
    
    if [ "$LOCATION_SOURCE" = "default" ]; then
        read -p "Enter Azure region (default: $LOCATION): " input_location
        if [ -n "$input_location" ]; then
            export LOCATION="$input_location"
        fi
    fi
    
    if [ "$DOMAIN_SOURCE" = "default" ]; then
        read -p "Enter domain name (default: $DOMAIN_NAME_APPSERV): " input_domain
        if [ -n "$input_domain" ]; then
            export DOMAIN_NAME_APPSERV="$input_domain"
        fi
    fi
    
    print_success "Configuration:"
    print_success "  Base Name: $BASE_NAME"
    print_success "  Location: $LOCATION"  
    print_success "  Domain: $DOMAIN_NAME_APPSERV"
    echo ""
    
    # Choose deployment mode
    choose_deployment_mode
    
    # Execute based on chosen mode
    case $DEPLOYMENT_MODE in
        "single-subscription")
            create_single_subscription_demo
            update_parameters_file
            deploy_main_infrastructure
            ;;
        "multi-subscription")
            configure_multi_subscription
            create_multi_subscription_demo
            update_parameters_file
            deploy_main_infrastructure
            ;;
        "true-alz")
            validate_existing_alz
            deploy_main_infrastructure
            ;;
    esac
    
    save_deployment_variables
    
    print_header "DEPLOYMENT COMPLETED SUCCESSFULLY!"
    
    print_success "Next steps:"
    print_success "1. Deploy jump box (optional): az deployment group create -f ./infra-as-code/bicep/jumpbox/jumpbox.bicep -g $RESOURCE_GROUP -p @./infra-as-code/bicep/jumpbox/parameters.json -p baseName=$BASE_NAME"
    print_success "2. Create AI agent from jump box or connected network"
    print_success "3. Deploy web application"
    print_success "4. Test the complete solution"
    echo ""
    print_status "For detailed next steps, see the README.md file"
}

# Run main function
main
