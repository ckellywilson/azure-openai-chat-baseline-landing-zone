#!/bin/bash

# Deployment Status Checker
# This script helps monitor and validate your Azure OpenAI Chat Baseline Landing Zone deployment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}"
}

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

# Function to check if deployment variables are available
check_deployment_vars() {
    if [ -f "deployment-vars.env" ]; then
        source deployment-vars.env
        print_success "Deployment variables loaded from deployment-vars.env"
    else
        print_warning "deployment-vars.env not found. Run the deployment script first or set variables manually."
        return 1
    fi
}

# Function to check Azure login status
check_azure_login() {
    print_header "CHECKING AZURE AUTHENTICATION"
    
    if az account show &> /dev/null; then
        local current_sub=$(az account show --query "{id:id, name:name}" -o json)
        local sub_id=$(echo "$current_sub" | jq -r '.id')
        local sub_name=$(echo "$current_sub" | jq -r '.name')
        print_success "Logged into Azure: $sub_name ($sub_id)"
    else
        print_error "Not logged into Azure. Run 'az login' first."
        return 1
    fi
}

# Function to check deployment status
check_deployment_status() {
    print_header "CHECKING DEPLOYMENT STATUS"
    
    if [ -z "$BASE_NAME" ]; then
        print_error "BASE_NAME not set. Load deployment variables first."
        return 1
    fi
    
    local deployment_name="ai-foundry-chat-prereq-lz-baseline-${BASE_NAME}"
    
    print_status "Checking main deployment: $deployment_name"
    
    local deployment_state=$(az deployment sub show --name "$deployment_name" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    
    case "$deployment_state" in
        "Succeeded")
            print_success "Main deployment completed successfully"
            ;;
        "Running"|"Accepted")
            print_warning "Main deployment is still in progress..."
            az deployment sub show --name "$deployment_name" --query "{State:properties.provisioningState, Progress:properties.outputs}" -o table
            ;;
        "Failed")
            print_error "Main deployment failed"
            az deployment sub show --name "$deployment_name" --query "properties.error" -o json
            return 1
            ;;
        "NotFound")
            print_error "Main deployment not found. Has the deployment been started?"
            return 1
            ;;
        *)
            print_warning "Main deployment state: $deployment_state"
            ;;
    esac
    
    # Check AI Foundry project deployment if main deployment succeeded
    if [ "$deployment_state" = "Succeeded" ] && [ -n "$RESOURCE_GROUP" ]; then
        local ai_deployment_name="ai-foundry-chat-lz-baseline-${BASE_NAME}"
        print_status "Checking AI Foundry project deployment: $ai_deployment_name"
        
        local ai_deployment_state=$(az deployment group show --name "$ai_deployment_name" --resource-group "$RESOURCE_GROUP" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
        
        case "$ai_deployment_state" in
            "Succeeded")
                print_success "AI Foundry project deployment completed successfully"
                ;;
            "Running"|"Accepted")
                print_warning "AI Foundry project deployment is still in progress..."
                ;;
            "Failed")
                print_error "AI Foundry project deployment failed"
                az deployment group show --name "$ai_deployment_name" --resource-group "$RESOURCE_GROUP" --query "properties.error" -o json
                ;;
            "NotFound")
                print_warning "AI Foundry project deployment not started yet"
                ;;
            *)
                print_warning "AI Foundry project deployment state: $ai_deployment_state"
                ;;
        esac
    fi
}

# Function to check resource group and resources
check_resources() {
    print_header "CHECKING DEPLOYED RESOURCES"
    
    if [ -z "$RESOURCE_GROUP" ]; then
        print_error "RESOURCE_GROUP not set. Load deployment variables first."
        return 1
    fi
    
    # Check if resource group exists
    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_success "Resource group exists: $RESOURCE_GROUP"
        
        # List key resources
        print_status "Listing key resources in $RESOURCE_GROUP:"
        
        # Count resources by type
        local storage_count=$(az storage account list --resource-group "$RESOURCE_GROUP" --query "length([*])" -o tsv)
        local cosmosdb_count=$(az cosmosdb list --resource-group "$RESOURCE_GROUP" --query "length([*])" -o tsv)
        local search_count=$(az search service list --resource-group "$RESOURCE_GROUP" --query "length([*])" -o tsv)
        local appservice_count=$(az webapp list --resource-group "$RESOURCE_GROUP" --query "length([*])" -o tsv)
        local keyvault_count=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "length([*])" -o tsv)
        local appgw_count=$(az network application-gateway list --resource-group "$RESOURCE_GROUP" --query "length([*])" -o tsv)
        
        echo "  - Storage Accounts: $storage_count"
        echo "  - Cosmos DB Accounts: $cosmosdb_count"
        echo "  - AI Search Services: $search_count"
        echo "  - App Services: $appservice_count"
        echo "  - Key Vaults: $keyvault_count"
        echo "  - Application Gateways: $appgw_count"
        
        # Check specific named resources if variables are available
        if [ -n "$AIFOUNDRY_NAME" ]; then
            if az cognitiveservices account show --name "$AIFOUNDRY_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
                print_success "AI Foundry account found: $AIFOUNDRY_NAME"
            else
                print_warning "AI Foundry account not found: $AIFOUNDRY_NAME"
            fi
        fi
        
        if [ -n "$STORAGE_ACCOUNT_NAME" ]; then
            if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
                print_success "Storage account found: $STORAGE_ACCOUNT_NAME"
            else
                print_warning "Storage account not found: $STORAGE_ACCOUNT_NAME"
            fi
        fi
        
    else
        print_error "Resource group not found: $RESOURCE_GROUP"
        return 1
    fi
}

# Function to check network connectivity
check_networking() {
    print_header "CHECKING NETWORK CONFIGURATION"
    
    if [ -z "$RESOURCE_GROUP" ]; then
        print_error "RESOURCE_GROUP not set. Cannot check networking."
        return 1
    fi
    
    # Check for subnets
    print_status "Checking subnet deployments..."
    
    # This requires knowing the spoke VNet details - extract from parameters if available
    if [ -f "./infra-as-code/bicep/parameters.alz.json" ]; then
        local spoke_vnet_id=$(jq -r '.parameters.existingResourceIdForSpokeVirtualNetwork.value' ./infra-as-code/bicep/parameters.alz.json)
        if [[ "$spoke_vnet_id" != *"YOUR-"* ]]; then
            local vnet_rg=$(echo "$spoke_vnet_id" | cut -d'/' -f5)
            local vnet_name=$(echo "$spoke_vnet_id" | cut -d'/' -f9)
            
            print_status "Checking subnets in $vnet_name (RG: $vnet_rg)..."
            
            local subnet_count=$(az network vnet subnet list --vnet-name "$vnet_name" --resource-group "$vnet_rg" --query "length([*])" -o tsv)
            print_status "Total subnets in spoke VNet: $subnet_count"
            
            # List subnets with our naming pattern
            az network vnet subnet list --vnet-name "$vnet_name" --resource-group "$vnet_rg" \
                --query "[?contains(name, 'snet-')].{Name:name, AddressPrefix:addressPrefix, Status:provisioningState}" -o table
        else
            print_warning "Spoke VNet not configured in parameters.alz.json"
        fi
    else
        print_warning "Parameters file not found - cannot check network configuration"
    fi
    
    # Check Application Gateway if deployed
    local appgw_name="${BASE_NAME}-appgw"
    if az network application-gateway show --name "$appgw_name" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        local appgw_status=$(az network application-gateway show --name "$appgw_name" --resource-group "$RESOURCE_GROUP" --query "operationalState" -o tsv)
        print_success "Application Gateway status: $appgw_status"
    else
        print_warning "Application Gateway not found or not yet deployed"
    fi
}

# Function to display next steps
show_next_steps() {
    print_header "NEXT STEPS"
    
    local deployment_name="ai-foundry-chat-prereq-lz-baseline-${BASE_NAME}"
    local deployment_state=$(az deployment sub show --name "$deployment_name" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    
    if [ "$deployment_state" = "Succeeded" ]; then
        echo -e "${GREEN}✅ Infrastructure deployment completed successfully!${NC}"
        echo ""
        echo "What you can do now:"
        echo "1. Deploy a jump box (if needed):"
        echo "   az deployment group create -f ./infra-as-code/bicep/jumpbox/jumpbox.bicep \\"
        echo "     -g $RESOURCE_GROUP \\"
        echo "     -p @./infra-as-code/bicep/jumpbox/parameters.json \\"
        echo "     -p baseName=$BASE_NAME"
        echo ""
        echo "2. Connect to the virtual network and create an AI agent"
        echo "3. Test the chat application through the Application Gateway"
        echo ""
        echo "📖 For detailed next steps, see the main README.md"
    elif [ "$deployment_state" = "Running" ] || [ "$deployment_state" = "Accepted" ]; then
        echo -e "${YELLOW}⏳ Deployment is still in progress${NC}"
        echo ""
        echo "You can:"
        echo "1. Monitor progress: az deployment sub show --name $deployment_name"
        echo "2. Run this status check again: ./check-status.sh"
        echo "3. Check the Azure portal for detailed progress"
    elif [ "$deployment_state" = "Failed" ]; then
        echo -e "${RED}❌ Deployment has failed${NC}"
        echo ""
        echo "You should:"
        echo "1. Check the deployment errors above"
        echo "2. Review the Azure portal for detailed error information"
        echo "3. Fix any configuration issues and retry deployment"
    else
        echo -e "${YELLOW}ℹ️ Deployment status is unclear${NC}"
        echo ""
        echo "Check if deployment was started:"
        echo "1. Run ./deploy-complete-enhanced.sh to start deployment"
        echo "2. Check the Azure portal for any existing deployments"
    fi
}

# Main execution
main() {
    print_header "AZURE OPENAI CHAT BASELINE LANDING ZONE - STATUS CHECK"
    
    check_azure_login || exit 1
    check_deployment_vars || exit 1
    check_deployment_status
    check_resources
    check_networking
    show_next_steps
    
    print_success "Status check completed"
}

# Help function
show_help() {
    echo "Azure OpenAI Chat Baseline Landing Zone - Status Checker"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "This script checks the status of your deployment including:"
    echo "  - Azure authentication status"
    echo "  - Deployment progress and state"
    echo "  - Deployed resources verification"
    echo "  - Network configuration validation"
    echo "  - Next steps recommendations"
    echo ""
    echo "Prerequisites:"
    echo "  - Azure CLI installed and logged in"
    echo "  - deployment-vars.env file (created by deploy-complete-enhanced.sh)"
    echo "  - jq installed for JSON processing"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
