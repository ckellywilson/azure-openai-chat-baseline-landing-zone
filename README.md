# Azure AI Foundry Agent Service chat baseline reference implementation in an application landing zone

This reference implementation extends the foundation set in the [Azure AI Foundry Agent Service chat baseline](https://github.com/Azure-Samples/openai-end-to-end-baseline/) reference implementation. Specifically, this repository takes that reference implementation and deploys it within an application landing zone.

If you haven't yet, you should start by reviewing the [Baseline Azure AI Foundry chat reference architecture in an Azure landing zone](https://learn.microsoft.com/azure/architecture/ai-ml/architecture/azure-openai-baseline-zone) article on Microsoft Learn. It sets important context for this implementation that is not covered in this deployment guide.

## 📋 **Deployment Overview**

This repository provides **three deployment approaches** to suit different scenarios:

1. **Single-Subscription Demo** - Everything deployed in one subscription for learning
2. **Multi-Subscription Demo** - Realistic hub-spoke simulation across subscriptions  
3. **True Application Landing Zone** - Production deployment using existing platform resources

All approaches use the same primary deployment script (`deploy-complete-enhanced.sh`) with interactive mode to guide you through the process.

## 🚀 **Quick Start - Choose Your Deployment Approach**

**Select the deployment approach that matches your scenario:**

### **Step 1: Pick Your Deployment Scenario**

| Scenario | When to Use | Script Command |
|----------|-------------|----------------|
| **1. Single-Subscription Demo** | Learning, quick demos, development | `./deploy-complete-enhanced.sh` |
| **2. Multi-Subscription Demo** | Realistic testing, POCs, learning ALZ patterns | `./deploy-complete-enhanced.sh` |
| **3. True Application Landing Zone** | Production with existing platform infrastructure | `./setup-parameters.sh` then `./deploy-complete-enhanced.sh` |

### **Step 2: Decision Tree**

```
Do you have existing platform resources (spoke VNet, UDR)?
├─ YES → Use "True Application Landing Zone" (Scenario 3)
└─ NO → Do you need to simulate multi-subscription ALZ?
    ├─ YES → Use "Multi-Subscription Demo" (Scenario 2)  
    └─ NO → Use "Single-Subscription Demo" (Scenario 1)
```

### **Step 3: Run Your Selected Approach**

> **🎯 Ready to deploy? Most users should start here:**
> ```bash
> ./deploy-complete-enhanced.sh
> ```
> The script will interactively guide you through selecting the right scenario and configuring your deployment.

**For automated/non-interactive deployment:**
```bash
export BASE_NAME="myapp01"
export LOCATION="eastus2"  
export DOMAIN_NAME_APPSERV="mycompany.com"
./deploy-complete-enhanced.sh
```

**For True ALZ deployments, run setup first:**
```bash
./setup-parameters.sh  # Configure existing platform resources
./deploy-complete-enhanced.sh  # Deploy application
```

## 🎯 **Detailed Deployment Scenarios**

### **1. 🧪 Single-Subscription Demo**
- **Best for:** Learning, quick demos, development
- **What it creates:** Everything in your current subscription
- **Includes:** Simulated hub-spoke in one subscription
- **Limitations:** NOT suitable for production use

### **2. 🏢 Multi-Subscription Demo**
- **Best for:** Realistic testing, POCs, learning ALZ patterns
- **What it creates:** Hub resources in "Platform" subscription, App resources in "Application" subscription
- **Includes:** Cross-subscription peering, centralized DNS zones, realistic hub-spoke
- **More realistic:** Mirrors actual enterprise ALZ patterns

### **3. 🎯 True Application Landing Zone**
- **Best for:** Production deployments
- **Requirements:** Existing platform-provided spoke VNet and UDR
- **Uses:** Real platform resources managed by your platform team
- **Prerequisites:** Run `./setup-parameters.sh` first

## 📝 **Configuration Reference**

**Environment Variables (all optional with interactive prompts):**
- `BASE_NAME`: 6-8 characters, lowercase letters and numbers only
- `LOCATION`: Azure region (e.g., "eastus2", "westus2")
- `DOMAIN_NAME_APPSERV`: Custom domain for Application Gateway (defaults to "contoso.com")

**Multi-Subscription Additional Variables:**
- `PLATFORM_SUBSCRIPTION_ID`: Connectivity/Platform subscription ID
- `APPLICATION_SUBSCRIPTION_ID`: Application workload subscription ID

## 🚀 **Ready to Deploy?**

1. **Choose your deployment scenario** using the decision tree above
2. **For True ALZ**: Run `./setup-parameters.sh` first to configure platform resources  
3. **Run the deployment**: `./deploy-complete-enhanced.sh`
4. **Monitor progress**: Use `./check-status.sh` during deployment
5. **Deploy agents and test**: Follow the post-deployment instructions

> **💡 First time?** Start with the **Single-Subscription Demo** to learn the system before moving to production scenarios.

## 🔄 **What Happens During Deployment**

The deployment process includes these automated steps:

- ✅ **Prerequisites Check**: Validates Azure CLI, OpenSSL installation
- ✅ **Resource Providers**: Automatically registers required providers  
- ✅ **Certificate Generation**: Creates self-signed certificates for demo purposes
- ✅ **Infrastructure Deployment**: Deploys main Bicep template with all dependencies (~20 minutes)
- ✅ **AI Foundry Setup**: Deploys AI Foundry project and agent capability (~5 minutes)
- ✅ **Environment Export**: Saves all deployment variables to `deployment-vars.env` for later use

### 🛠️ **Key Helper Scripts**

#### setup-parameters.sh (Required for True ALZ)
Interactive configuration script for ALZ deployments:
- Validates Azure access and platform resource availability
- Configures spoke VNet and UDR resource IDs
- Sets up subnet address prefixes within your VNet's address space
- Creates backups of existing configuration

```bash
./setup-parameters.sh              # Interactive configuration
./setup-parameters.sh --validate   # Validate existing configuration
./setup-parameters.sh --help       # Show help
```

### Monitoring Deployment Progress

During and after deployment, you can monitor the status using the included status checker:

```bash
# Check deployment status and validate resources
./check-status.sh
```

The status checker provides:
- ✅ Azure authentication verification
- ✅ Deployment progress monitoring
- ✅ Resource validation and counting
- ✅ Network configuration checks
- ✅ Context-aware next steps guidance

This is particularly useful for:
- **During deployment**: Monitor progress of long-running deployments
- **After deployment**: Verify all resources were created successfully
- **Troubleshooting**: Get specific error details and remediation steps
- **Before next steps**: Confirm readiness before agent deployment or testing

## 🤖 **Post-Deployment: Setting Up AI Agents**

Once your infrastructure deployment is complete, you need to create and configure AI agents in Azure AI Foundry. The deployment has already set up the foundation, but you need to create the actual agent that your web application will use.

### **What's Already Deployed**

The infrastructure deployment has already created:
- ✅ **Azure AI Foundry Hub**: The main AI service with private endpoints
- ✅ **OpenAI Model**: GPT-4o model deployment named `agent-model` (50K TPM capacity)
- ✅ **Bing Search**: Connected for web grounding capabilities
- ✅ **AI Search Service**: For vector search and RAG capabilities
- ✅ **Storage & Cosmos DB**: For agent state and conversation management
- ✅ **Networking**: All private endpoints and subnets configured

### **What You Need to Do**

You need to create an **AI Agent** that uses these deployed resources to provide chat functionality.

### **Step-by-Step AI Agent Setup**

#### **Option A: Using Jump Box (Recommended)**

If you need network access to the private AI Foundry endpoints, deploy a jump box first:

```bash
# Deploy jump box for network access
az deployment group create \
  -f ./infra-as-code/bicep/jumpbox/jumpbox.bicep \
  -g rg-demo01-workload \
  -p @./infra-as-code/bicep/jumpbox/parameters.json \
  -p baseName=demo01
```

**1. Connect to Jump Box and Set Environment Variables**

```powershell
# Set these variables based on your deployment
$BASE_NAME = "demo01"
$RESOURCE_GROUP = "rg-${BASE_NAME}-workload"

# Get deployed resource names
$AI_FOUNDRY_NAME = $(az resource list -g $RESOURCE_GROUP --resource-type "Microsoft.CognitiveServices/accounts" --query "[0].name" -o tsv)
$BING_ACCOUNT_NAME = $(az resource list -g $RESOURCE_GROUP --resource-type "Microsoft.Bing/accounts" --query "[0].name" -o tsv)

# Set up agent configuration variables
$AI_FOUNDRY_PROJECT_NAME = "projchat"
$MODEL_CONNECTION_NAME = "agent-model"
$BING_CONNECTION_NAME = $BING_ACCOUNT_NAME
$BING_CONNECTION_ID = "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.CognitiveServices/accounts/${AI_FOUNDRY_NAME}/projects/${AI_FOUNDRY_PROJECT_NAME}/connections/${BING_CONNECTION_NAME}"
$AI_FOUNDRY_AGENT_CREATE_URL = "https://${AI_FOUNDRY_NAME}.services.ai.azure.com/api/projects/${AI_FOUNDRY_PROJECT_NAME}/assistants?api-version=2025-05-15-preview"

# Verify the configuration
Write-Host "AI Foundry Hub: $AI_FOUNDRY_NAME"
Write-Host "Model Connection: $MODEL_CONNECTION_NAME"
Write-Host "Bing Connection ID: $BING_CONNECTION_ID"
Write-Host "Agent API URL: $AI_FOUNDRY_AGENT_CREATE_URL"
```

**2. Download and Configure the Agent Definition**

```powershell
# Download the pre-configured agent template
Invoke-WebRequest -Uri "https://github.com/Azure-Samples/azure-openai-chat-baseline-landing-zone/raw/refs/heads/main/agents/chat-with-bing.json" -OutFile "chat-with-bing.json"

# Read and update the template with your specific resource names
$agentJson = Get-Content "chat-with-bing.json" -Raw
$agentJson = $agentJson -replace 'MODEL_CONNECTION_NAME', $MODEL_CONNECTION_NAME
$agentJson = $agentJson -replace 'BING_CONNECTION_ID', $BING_CONNECTION_ID
$agentJson | Out-File "chat-with-bing-configured.json" -Encoding utf8

# Verify the configuration looks correct
Get-Content "chat-with-bing-configured.json"
```

**3. Create the AI Agent**

```powershell
# Deploy the agent to AI Foundry
az rest -u $AI_FOUNDRY_AGENT_CREATE_URL -m "post" --resource "https://ai.azure.com" -b @chat-with-bing-configured.json

# Verify the agent was created and get its ID
$AGENT_ID = $(az rest -u $AI_FOUNDRY_AGENT_CREATE_URL -m 'get' --resource 'https://ai.azure.com' --query 'data[0].id' -o tsv)
Write-Host "Created Agent ID: $AGENT_ID"

# Save the Agent ID for later use
$AGENT_ID | Out-File "agent-id.txt" -Encoding utf8
```

#### **Option B: Using AI Foundry Portal (Alternative)**

If you prefer using the web interface:

**1. Access AI Foundry Portal**
- From your jump box or network-connected machine, go to: `https://ai.azure.com`
- Sign in and navigate to your AI Foundry project named **projchat**

**2. Create a New Agent**
- Click **"Agents"** in the left navigation
- Click **"+ New agent"**
- Choose **"Create agent"**

**3. Configure the Agent**
- **Name**: `Baseline Chatbot Agent`
- **Description**: `Example agent that uses Bing Search for grounded responses`
- **Model**: Select `agent-model` (GPT-4o deployment)
- **Instructions**: 
  ```
  You are a helpful Chatbot agent. You'll consult the Bing Search tool to answer questions. Always search the web for information before responding.
  ```

**4. Add Bing Search Tool**
- Click **"Add tool"** → **"Bing Search"**
- Select your Bing connection
- Set **Count**: `5`
- Set **Freshness**: `Week`

**5. Save and Deploy the Agent**
- Click **"Save"** to create the agent
- Note the **Agent ID** from the URL or agent details

#### **Step 4: Configure the Web Application**

Back from your jump box, configure the web app to use your new agent:

```powershell
# Get the AI Foundry project endpoint
$AI_FOUNDRY_ENDPOINT = "https://${AI_FOUNDRY_NAME}.services.ai.azure.com"
$AI_PROJECT_ENDPOINT = "${AI_FOUNDRY_ENDPOINT}/api/projects/${AI_FOUNDRY_PROJECT_NAME}"

# Update the web app configuration
az webapp config appsettings set -n "app-${BASE_NAME}" -g $RESOURCE_GROUP --settings AIProjectEndpoint="${AI_PROJECT_ENDPOINT}"
az webapp config appsettings set -n "app-${BASE_NAME}" -g $RESOURCE_GROUP --settings AIAgentId="${AGENT_ID}"

# Restart the web app to apply new settings
az webapp restart --name "app-${BASE_NAME}" --resource-group $RESOURCE_GROUP
```

#### **Step 5: Deploy the Web Application Code**

```powershell
# Download the pre-built web application
Invoke-WebRequest -Uri "https://github.com/Azure-Samples/azure-openai-chat-baseline-landing-zone/raw/refs/heads/main/website/chatui.zip" -OutFile "chatui.zip"

# Upload to the web app's storage account
$WEBAPP_STORAGE = $(az storage account list -g $RESOURCE_GROUP --query "[?contains(name, 'stwebapp')].name" -o tsv)
az storage blob upload -f chatui.zip --account-name $WEBAPP_STORAGE --auth-mode login -c deploy -n chatui.zip

# Restart the web app to load the new code
az webapp restart --name "app-${BASE_NAME}" --resource-group $RESOURCE_GROUP
```

### **Testing Your Setup**

#### **Test the Agent in AI Foundry Portal (Optional)**
1. From your jump box, go to `https://ai.azure.com`
2. Navigate to your **projchat** project
3. Click **"Agents"** → Select your **"Baseline Chatbot Agent"**
4. Click **"Try in playground"**
5. Ask a question that requires recent information (e.g., "What's the weather like in Seattle today?")
6. Verify you get a grounded response with current information

#### **Test the Complete Web Application**
1. **From your local machine**, get the Application Gateway public IP:
   ```bash
   source deployment-vars.env  # Load saved variables
   APPGW_PUBLIC_IP=$(az network public-ip show -g $RESOURCE_GROUP -n "pip-$BASE_NAME" --query ipAddress --output tsv)
   echo "Application Gateway IP: $APPGW_PUBLIC_IP"
   ```

2. **Add DNS entry**: Edit your hosts file (`/etc/hosts` or `C:\Windows\System32\drivers\etc\hosts`) and add:
   ```
   <APPGW_PUBLIC_IP> www.contoso.com
   ```

3. **Browse to your application**: Go to `https://www.contoso.com`
   - Accept the self-signed certificate warning
   - Ask questions that require web search (e.g., recent news, weather, current events)
   - Verify the agent provides accurate, current responses

### **Troubleshooting Agent Setup**

**Agent Creation Fails:**
- Verify you're connected to the network (from jump box)
- Check that all resource names are correct
- Ensure the Bing connection exists: `az cognitiveservices account show -n <bing-account-name> -g <resource-group>`

**Web App Can't Connect to Agent:**
- Verify the `AIProjectEndpoint` and `AIAgentId` settings are correct
- Check that private endpoints are working: `nslookup <ai-foundry-name>.services.ai.azure.com`
- Restart the web app after configuration changes

**No Current Information in Responses:**
- Verify the Bing Search tool is properly configured
- Check that the agent instructions include "search the web"
- Test the Bing connection independently in AI Foundry

## 📚 **Additional Resources**

The following Microsoft Learn documentation provides detailed guidance for the components and processes covered in this implementation:

### **Azure AI Foundry & Agent Service**
- [**Quickstart: Get started with Azure AI Foundry**](https://learn.microsoft.com/en-us/azure/ai-foundry/quickstarts/get-started-code?tabs=azure-ai-foundry&pivots=fdp-project) - Complete getting started guide for AI Foundry
- [**Set up your agent environment**](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/environment-setup#set-up-your-agent-environment) - Prerequisites and environment setup
- [**Quickstart: Create a new agent**](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/quickstart#create-a-foundry-account-and-project-in-azure-ai-foundry-portal) - Step-by-step agent creation
- [**Work with Azure AI Foundry Agent Service in Visual Studio Code**](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/vs-code-agents#create-and-edit-azure-ai-agents-within-the-designer-view) - VS Code extension for agent development

### **Agent Tools Configuration**
- [**Grounding with Bing Search**](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/tools/bing-grounding#setup) - Configure Bing Search tool for web grounding
- [**How to use Grounding with Bing Search (portal)**](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/tools/bing-code-samples) - Portal-based Bing Search configuration
- [**Grounding with Bing Custom Search**](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/tools/bing-custom-search#setup) - Advanced Bing Search with custom domains
- [**Available tools for Azure AI Agents**](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/vs-code-agents#add-tools-to-the-azure-ai-agent) - Complete list of agent tools

### **Web Application & App Service**
- [**Tutorial: Build an agentic web app in Azure App Service**](https://learn.microsoft.com/en-us/azure/app-service/tutorial-ai-agent-web-app-semantic-kernel-foundry-dotnet#create-and-configure-the-azure-ai-foundry-resource) - Complete tutorial for AI-powered web apps
- [**Configure an App Service app**](https://learn.microsoft.com/en-us/azure/app-service/configure-common#configure-general-settings) - App Service configuration and settings
- [**Environment variables and app settings in Azure App Service**](https://learn.microsoft.com/en-us/azure/app-service/reference-app-settings#deployment) - App configuration management
- [**Deploy to Azure App Service by using Azure Pipelines**](https://learn.microsoft.com/en-us/azure/app-service/deploy-azure-pipelines#2-add-the-deployment-task) - CI/CD deployment guidance

### **Landing Zone Architecture**
- [**What is an Azure landing zone?**](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/#platform-landing-zones-vs-application-landing-zones) - Landing zone concepts and architecture
- [**Deploy Azure landing zones**](https://learn.microsoft.com/en-us/azure/architecture/landing-zones/landing-zone-deploy#application-landing-zone-architectures) - Application landing zone patterns
- [**Prepare your landing zone for migration**](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/ready-azure-landing-zone#routing) - Network routing and connectivity
- [**Application landing zone accelerators**](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/#application-landing-zone-accelerators) - Pre-built landing zone templates

### **Application Gateway & Networking**
- [**Reliability in Azure Application Gateway v2**](https://learn.microsoft.com/en-us/azure/reliability/reliability-application-gateway-v2#availability-zone-support) - Application Gateway configuration and reliability
- [**Azure Application Gateway configuration**](https://learn.microsoft.com/en-us/azure/application-gateway/quick-create-portal) - Setup and configuration guidance

### **Security & Best Practices**
- [**Create a new network-secured environment**](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/virtual-networks#configure-a-new-network-secured-environment) - Network security for AI Foundry
- [**Azure AI Foundry Agent Service RBAC roles**](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/rbac-azure-ai-foundry) - Role-based access control
- [**What's new in Azure AI Foundry Agent Service**](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/whats-new#may-2025) - Latest features and updates

### **Reference Architecture**
- [**Baseline Azure AI Foundry chat reference architecture**](https://learn.microsoft.com/azure/architecture/ai-ml/architecture/azure-openai-baseline-zone) - Complete architectural guidance (referenced in this implementation)

These resources provide comprehensive documentation for understanding, implementing, and troubleshooting the components used in this Azure AI Foundry chat baseline landing zone implementation.

### Deploy Jump Box (Optional)

If you need a jump box for agent deployment and testing:

```bash
# Source the saved deployment variables (if using automated scripts)
source deployment-vars.env

# Deploy jump box
az deployment group create \
  -f ./infra-as-code/bicep/jumpbox/jumpbox.bicep \
  -g $RESOURCE_GROUP \
  -p "@./infra-as-code/bicep/jumpbox/parameters.json" \
  -p baseName=$BASE_NAME
```

## ✅ Prerequisites Checklist

### Platform Team Requirements (for True ALZ)

- [ ] Application landing zone subscription provisioned
- [ ] Spoke virtual network deployed (`/22` or larger)
- [ ] DNS configuration set for hub-based resolution
- [ ] VNet peering established (hub ↔ spoke)
- [ ] UDR deployed for internet traffic (if not using VWAN)
- [ ] Private endpoint DNS resolution configured
- [ ] Required Azure resource providers registered

### Required Azure Quota

- [ ] Application Gateways: 1 WAF_v2 tier instance
- [ ] App Service Plans: P1v3 (AZ), 3 instances
- [ ] Azure AI Search: 1 Standard tier
- [ ] Azure Cosmos DB: 1 account
- [ ] Azure OpenAI: GPT-4o model with 50K TPM capacity
- [ ] Public IPv4 Addresses: 4 Standard tier
- [ ] Storage Accounts: 2

### User Permissions

- [ ] `User Access Administrator` or `Owner` on subscription
- [ ] `Cognitive Services Contributor` for AI services
- [ ] Access to platform-provided spoke VNet and UDR resources (for True ALZ)

### Local Development Environment

- [ ] [Azure CLI installed](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [ ] [OpenSSL CLI installed](https://docs.openssl.org/3.3/man7/ossl-guide-introduction/#getting-and-installing-openssl)

*If you're using WSL, ensure the Azure CLI is installed in WSL and not using the Windows version. `which az` should show `/usr/bin/az`.*

## 🔍 Troubleshooting

### Common Issues

1. **Platform Resources Not Found** (True ALZ scenarios)
   ```bash
   # Validate your configuration
   ./setup-parameters.sh --validate
   ```

2. **Deployment Progress Monitoring**
   ```bash
   # Check deployment status and progress
   ./check-status.sh
   ```

3. **DNS Resolution Issues**
   - Ensure platform team has configured DNS forwarding
   - Wait for private endpoint DNS propagation (~5-10 minutes)
   - Check DINE policy deployment for private DNS zones

4. **Quota Issues**
   - Request quota increases for required resources
   - Check region availability for all services

5. **Permission Issues**
   - Verify subscription-level permissions
   - Ensure access to platform networking resources

### Validation Commands

```bash
# Check current subscription and permissions
az account show
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --scope /subscriptions/$(az account show --query id -o tsv)

# Validate platform resources (True ALZ only)
az network vnet show --ids "/subscriptions/.../virtualNetworks/vnet-spoke"
az network route-table show --ids "/subscriptions/.../routeTables/udr-to-hub"

# Check resource providers
az provider list --query "[?registrationState=='Registered'].namespace" -o table
```

## Manual Deployment Guide

*For advanced customization, learning purposes, or when you need step-by-step control over the deployment process.*

### Application Landing Zone Context

This application landing zone deployment guide assumes you are using a typical Azure landing zone approach with platform and workload separation. This deployment assumes many pre-existing platform resources and deploys nothing outside of the scope of the application landing zone. That means to fully deploy this repo, it must be done so as part of your organization's actual subscription vending process. If you do not have the ability to deploy into an actual application landing zone, then consider using the demo deployment option above.

> [!IMPORTANT]
> Because organizations may implement landing zones differently, it is *expected* that you will need to further adjust the deployment beyond the configuration provided.

### Differences from the Azure OpenAI end-to-end chat baseline reference implementation

The key differences when integrating the Azure AI Foundry Agent Service chat baseline into an application landing zone as opposed to a fully standalone deployment are as follows:

- **Virtual network**: The virtual network will be deployed and configured by the platform team. This involves them providing a UDR and DNS configuration on the virtual network. The subnets are still under the control of the workload team.

- **DNS forwarding**: Rather than using local DNS settings, the application's virtual network likely will be configured to use central DNS servers, such as Azure Firewall DNS Proxy or Azure Private DNS Resolver, for DNS forwarding. This centralizes DNS management and ensures consistency across the landscape.

  | :warning: | Azure AI Foundry will require Azure Private DNS resolver to inject specific rules to resolve its dependencies. |
  | :-------: | :------------------------- |

- **Bastion host**: Instead of deploying an Azure Bastion host within the application's landing zone, a centralized bastion service already provisioned within the platform landing zone subscriptions is used. This means all remote administrative traffic is routed through a common, secure access point, adhering to the principle of least privilege and centralized auditing.

- **Private DNS Zones**: Private endpoints within the application need to be integrated with centralized private DNS zones that are managed at the platform landing zone level. Such DNS zones might be shared across multiple applications or environments, simplifying the DNS management and providing an organized approach to name resolution.

- **Network virtual appliance (NVA)**: the centralized NVA and user-defined routes (UDRs) configurations are now managed by the platform team and has been relocated to the hub.

- **Compliance with centralized governance**: An application landing zone comes with predefined governance policies regarding resource provisioning, network configurations, and security settings. Integrating with the Azure landing zone structure demands compliance with these policies, ensuring that all deployments meet the organization's regulatory, compliance, and governance standards.

### Integration with existing platform services

Partial configuration for this scenario is in the **parameters.alz.json** file, currently specifies the subnet address prefixes for the following subnets:

- `snet-appGateway`: The subnet for the Azure Application Gateway.
- `snet-appServicePlan`: The subnet for the Azure App Service.
- `snet-privateEndpoints`: The subnet for the Azure Private Endpoint.
- `snet-agentsEgress`: The subnet for the Azure AI Foundry Agent Service.
- `snet-jumpBoxes`: The subnet for the jumboxes.
- `snet-buildAgents`: The subnet for the build agents.

## Architecture

Just like the baseline reference implementation, this implementation covers the same following three scenarios:

- [Setting up Azure AI Foundry to host agents](#setting-up-azure-ai-foundry-to-host-agents)
- [Deploying an agent into Azure AI Foundry Agent Service](#deploying-an-agent-into-azure-ai-foundry-agent-service)
- [Invoking the agent from .NET code hosted in an Azure Web App](#invoking-the-agent-from-net-code-hosted-in-an-azure-web-app)

![Diagram of the Architecture diagram of the workload, including select platform subscription resources.](docs/media/baseline-azure-ai-foundry-landing-zone.svg)

*Download a [Visio file](docs/media/baseline-azure-ai-foundry-landing-zone.vsdx) of this architecture.*

### Setting up Azure AI Foundry to host agents

Azure AI Foundry hosts Azure AI Foundry Agent Service as a capability. Foundry Agent service's REST APIs are exposed as an AI Foundry private endpoint within the network, and the agents' all egress through a delegated subnet which is routed through Azure Firewall for any internet traffic. This architecture deploys the Foundry Agent Service with its dependencies hosted within your own Azure Application landing zone subscription. As such, this architecture includes an Azure Storage account, Azure AI Search instance, and an Azure Cosmos DB account specifically for the Foundry Agent Service to manage.

### Deploying an agent into Azure AI Foundry Agent Service

Agents can be created via the Azure AI Foundry portal, Azure AI Persistent Agents client library, or the REST API. The creation and invocation of agents are a data plane operation. Since the data plane to Azure AI Foundry is private, all three of those are restricted to being executed from within a private network connected to the private endpoint of Azure AI Foundry.

Ideally agents should be source-controlled and a versioned asset. You then can deploy agents in a coordinated way with the rest of your workload's code. In this deployment guide, you'll create an agent from the jump box to simulate a deployment pipeline which could have created the agent.

If using the Azure AI Foundry portal is desired, then the web browser experience must be performed from a VM within the network or from a workstation that has VPN access to the private network and can properly resolve private DNS records.

### Invoking the agent from .NET code hosted in an Azure Web App

A chat UI application is deployed into a private Azure App Service. The UI is accessed through Application Gateway (WAF). The .NET code uses the Azure AI Persistent Agents client library to connect to the workload's agent. The endpoint for the agent is exposed exclusively through the Azure AI Foundry private endpoint.

## Deployment guide

> [!NOTE]
> Most users should use the [Quick Start Deployment Options](#-quick-start---choose-your-deployment-approach) above instead of this manual process. This section is provided for advanced customization scenarios.

Follow these instructions to deploy this example to your application landing zone subscription manually, try out what you've deployed, and learn how to clean up those resources.

> [!WARNING]
> The deployment steps assume you have an application landing zone already provisioned through your subscription vending process. This deployment will not work unless you have permission to manage subnets on an existing virtual network and means to ensure private endpoint DNS configuration (such as platform provided DINE Azure Policy). It also requires your platform team to have required NVA allowances on the hub's egress firewall and configured Azure DNS Forwarding rulesets targeting the Azure DNS Private Resolver input IP address for the following Azure AI Foundry capability host domain dependencies.

![Architecture diagram that focuses mostly on network ingress flows.](docs/media/baseline-landing-zone-networking.svg)

*Download a [Visio file](docs/media/baseline-landing-zone-networking.vsdx) of this architecture.*

### Manual deployment prerequisites

- You have an application landing zone subscription ready for this deployment that contains the following platform-provided resources:

  - One virtual network (spoke)
    - Must be at least a `/22`
    - DNS configuration set for hub-based resolution
    - Peering fully established between the hub and the spoke as well as the spoke and the hub
    - In the same region as your workload resources

  - One unassociated route table to force Internet-bound traffic through a platform-provided NVA *(if not using Azure VWAN)*
    - In the same region as your spoke virtual network

  - A mechanism to get private endpoint DNS registered with the DNS services configured in the virtual network. It also supports injecting specific domains and enables both centralized and distributed DNS registration as a fallback strategy. This ensures that, even when certain services such as Azure AI Foundry cannot rely on centralized DNS resolution, the mechanism can still inject domains like `documents.azure.com`, `search.windows.net`, and `blob.core.windows.net` as needed.

- The application landing zone subscription must have the following quota available in the location you'll select to deploy this implementation.

  - Application Gateways: 1 WAF_v2 tier instance
  - App Service Plans: P1v3 (AZ), 3 instances
  - Azure AI Search (S - Standard): 1
  - Azure Cosmos DB: 1 account
  - Azure OpenAI in Foundry Model: GPT-4o model deployment with 50k TPM capacity
  - Public IPv4 Addresses - Standard: 4
  - Storage Accounts: 2

- The application landing zone subscription must have the following resource providers [registered](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types#register-resource-provider).

  - `Microsoft.AlertsManagement`
  - `Microsoft.App`
  - `Microsoft.Bing`
  - `Microsoft.CognitiveServices`
  - `Microsoft.Compute`
  - `Microsoft.DocumentDB`
  - `Microsoft.Insights`
  - `Microsoft.KeyVault`
  - `Microsoft.ManagedIdentity`
  - `Microsoft.Network`
  - `Microsoft.OperationalInsights`
  - `Microsoft.Search`
  - `Microsoft.Storage`
  - `Microsoft.Web`

- Your deployment user must have the following permissions at the application landing zone subscription scope.

  - Ability to assign [Azure roles](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles) on newly created resource groups and resources. (E.g. `User Access Administrator` or `Owner`)
  - Ability to purge deleted AI services resources. (E.g. `Contributor` or `Cognitive Services Contributor`)

- The [Azure CLI installed](https://learn.microsoft.com/cli/azure/install-azure-cli)

  If you're executing this from WSL, be sure the Azure CLI is installed in WSL and is not using the version installed in Windows. `which az` should show `/usr/bin/az`.

- The [OpenSSL CLI](https://docs.openssl.org/3.3/man7/ossl-guide-introduction/#getting-and-installing-openssl) installed.

### 1. :rocket: Deploy the infrastructure

The following steps are required to deploy the infrastructure from the command line.

1. In your shell, clone this repo and navigate to the root directory of this repository.

   ```bash
   git clone https://github.com/Azure-Samples/azure-openai-chat-baseline-landing-zone
   cd azure-openai-chat-baseline-landing-zone
   ```

1. Log in and set the application landing zone subscription.

   ```bash
   az login
   az account set --subscription xxxxx
   ```

1. Obtain the App Gateway certificate

   Azure Application Gateway support for secure TLS using Azure Key Vault and managed identities for Azure resources. This configuration enables end-to-end encryption of the network traffic using standard TLS protocols. For production systems, you should use a publicly signed certificate backed by a public root certificate authority (CA). Here, we will use a self-signed certificate for demonstration purposes.

   - Set a variable for the domain used in the rest of this deployment.

     ```bash
     DOMAIN_NAME_APPSERV="contoso.com"
     ```

   - Generate a client-facing, self-signed TLS certificate.

     :warning: Do not use the certificate created by this script for actual deployments. The use of self-signed certificates are provided for ease of illustration purposes only. For your App Service solution, use your organization's requirements for procurement and lifetime management of TLS certificates, *even for development purposes*.

     Create the certificate that will be presented to web clients by Azure Application Gateway for your domain.

     ```bash
     openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out appgw.crt -keyout appgw.key -subj "/CN=${DOMAIN_NAME_APPSERV}/O=Contoso" -addext "subjectAltName = DNS:${DOMAIN_NAME_APPSERV}" -addext "keyUsage = digitalSignature" -addext "extendedKeyUsage = serverAuth"
     openssl pkcs12 -export -out appgw.pfx -in appgw.crt -inkey appgw.key -passout pass:
     ```

   - Base64 encode the client-facing certificate.

     :bulb: No matter if you used a certificate from your organization or generated one from above, you'll need the certificate (as `.pfx`) to be Base64 encoded for proper storage in Key Vault later.

     ```bash
     APP_GATEWAY_LISTENER_CERTIFICATE=$(cat appgw.pfx | base64 | tr -d '\n')
     echo APP_GATEWAY_LISTENER_CERTIFICATE: $APP_GATEWAY_LISTENER_CERTIFICATE
     ```

1. Update the **infra-as-code/bicep/parameters.alz.json** file with all references to your platform team's provided resources.

   You must set the following json values:

   - `existingResourceIdForSpokeVirtualNetwork`: The resource ID of the spoke virtual network the platform team deployed into your application landing zone subscription.
   - `existingResourceIdForUdrForInternetTraffic`: The resource ID of the UDR the platform team deployed into your application landing zone subscription. Leave blank if your platform team is using VWAN-provided route tables instead.
   - This parameters file contains the four `...AddressPrefix` values for the subnets in this architecture. The values must be within the platform-allocated address space for spoke and must be large enough for their respective services. Tip: Update the example ranges, not the subnet mask.

1. Set the resource deployment location to the location of where the virtual network was provisioned for you.

   The location one that [supports availability zones](https://learn.microsoft.com/azure/reliability/availability-zones-service-support) and has available quota. This deployment has been tested in the following locations: `australiaeast`, `eastus`, `eastus2`, `francecentral`, `japaneast`, `southcentralus`, `swedencentral`, `switzerlandnorth`, or `uksouth`. You might be successful in other locations as well.

   ```bash
   LOCATION=eastus2
   ```

1. Set the base name value that will be used as part of the Azure resource names for the resources deployed in this solution.

   ```bash
   BASE_NAME=<base resource name, between 6 and 8 lowercase characters, all DNS names will include this text, so it must be unique.>
   ```

1. Create a resource group and deploy the workload infrastructure prequisites.

   *There is an optional tracking ID on this deployment. To opt out of its use, add the following parameter to the deployment code below: `-p telemetryOptOut true`.*

   :clock8: *This might take about 20 minutes.*

   ```bash
   RESOURCE_GROUP="rg-chat-alz-baseline-${BASE_NAME}"
   az group create -l $LOCATION -n $RESOURCE_GROUP

   PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)

   az deployment sub create -f ./infra-as-code/bicep/main.bicep \
     -n ai-foundry-chat-prereq-lz-baseline-${BASE_NAME} \
     -l $LOCATION \
     -p workloadResourceGroupName=${RESOURCE_GROUP} \
     -p baseName=${BASE_NAME} \
     -p customDomainName=${DOMAIN_NAME_APPSERV} \
     -p appGatewayListenerCertificate=${APP_GATEWAY_LISTENER_CERTIFICATE} \
     -p yourPrincipalId=${PRINCIPAL_ID} \
     -p @./infra-as-code/bicep/parameters.alz.json
   ```

   | :warning: | Before you deploy Azure AI Foundry and its agent capability, you must wait until the Foundry Agent Service dependencies are fully resolvable to their private endpoints from within the spoke network. This requirement is especially important if DINE policies handle updates to DNS private zones. If you attempt to deploy the Foundry Agent Service capability before the private DNS records are resolvable from within your subnet, the deployment fails. |
   | :-------: | :------------------------- |

1. Get workload prequisites outputs

   ```bash
   AIFOUNDRY_NAME=$(az deployment sub show --name ai-foundry-chat-prereq-lz-baseline-${BASE_NAME} --query "properties.outputs.aiFoundryName.value" -o tsv)
   COSMOSDB_ACCOUNT_NAME=$(az deployment sub show --name ai-foundry-chat-prereq-lz-baseline-${BASE_NAME} --query "properties.outputs.cosmosDbAccountName.value" -o tsv)
   STORAGE_ACCOUNT_NAME=$(az deployment sub show --name ai-foundry-chat-prereq-lz-baseline-${BASE_NAME} --query "properties.outputs.storageAccountName.value" -o tsv)
   AISEARCH_ACCOUNT_NAME=$(az deployment sub show --name ai-foundry-chat-prereq-lz-baseline-${BASE_NAME} --query "properties.outputs.aiSearchAccountName.value" -o tsv)
   BING_ACCOUNT_NAME=$(az deployment sub show --name ai-foundry-chat-prereq-lz-baseline-${BASE_NAME} --query "properties.outputs.bingAccountName.value" -o tsv)
   WEBAPP_APPINSIGHTS_NAME=$(az deployment sub show --name ai-foundry-chat-prereq-lz-baseline-${BASE_NAME} --query "properties.outputs.webApplicationInsightsResourceName.value" -o tsv)
   ```

1. Deploy Azure AI Foundry project and agent capability host

   :clock9: *This might take about 5 minutes.*

   ```bash
   az deployment group create -f ./infra-as-code/bicep/ai-foundry-project.bicep \
     -n ai-foundry-chat-lz-baseline-${BASE_NAME} \
     -g ${RESOURCE_GROUP} \
     -p existingAiFoundryName=${AIFOUNDRY_NAME} \
     -p existingCosmosDbAccountName=${COSMOSDB_ACCOUNT_NAME} \
     -p existingStorageAccountName=${STORAGE_ACCOUNT_NAME} \
     -p existingAISearchAccountName=${AISEARCH_ACCOUNT_NAME} \
     -p existingBingAccountName=${BING_ACCOUNT_NAME} \
     -p existingWebApplicationInsightsResourceName=${WEBAPP_APPINSIGHTS_NAME}
   ```

### 2. Deploy an agent in the Azure AI Foundry Agent Service

To test this scenario, you'll be deploying an AI agent included in this repository. The agent uses a GPT model combined with a Bing search for grounding data. Deploying an AI agent requires data plane access to Azure AI Foundry. In this architecture, a network perimeter is established, and you must interact with the Azure AI Foundry portal and its resources from within the network.

The AI agent definition would likely be deployed from your application's pipeline running from a build agent in your workload's network or it could be deployed via singleton code in your web application. In this deployment, you'll create the agent from the jump box, which most closely simulates pipeline-based creation.

1. Deploy a jump box, **if necessary**. *Skip this if your platform team has provided workstation-based access or another method.*

   If you need to deploy a jump box into your application landing zone, this deployment guide has a simple one that you can use. You will be prompted for an admin password for the jump box; it must satisfy the [complexity requirements for Windows VM in Azure](https://learn.microsoft.com/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm-). You'll need to identify your landing zone virtual network as well in **infra-as-code/bicep/jumpbox/parameters.json**. This is the same value you used in **infra-as-code/bicep/parameters.alz.json**.

   *There is an optional tracking ID on this deployment. To opt out of the deployment tracking, add the following parameter to the deployment code below: `-p telemetryOptOut true`.*

   ```bash
   az deployment group create -f ./infra-as-code/bicep/jumpbox/jumpbox.bicep \
      -g $RESOURCE_GROUP \
      -p @./infra-as-code/bicep/jumpbox/parameters.json \
      -p baseName=$BASE_NAME
   ```

   The username for the Windows jump box deployed in this solution is `vmadmin`.

   Your hub's egress firewall will need various application rule allowances to support this use case. Below are some key destinations that need to be opened from your jump box's subnet:

   - `ai.azure.com:443`
   - `login.microsoftonline.com:443`
   - `login.live.com:443`
   - and many more...

1. Connect to the virtual network via the deployed [Azure Bastion and the jump box](https://learn.microsoft.com/azure/bastion/bastion-connect-vm-rdp-windows#rdp). Alternatively, you can connect through a force-tunneled VPN or virtual network peering that you manually configure apart from these instructions.

   | :computer: | Unless otherwise noted, the following steps are performed from the jump box or from your VPN-connected workstation. The instructions are written as if you are a Windows jump box. Adjust accordingly if using a Linux virtual machine. |
   | :--------: | :------------------------- |

1. Open PowerShell from the Terminal app. Log in and select your target subscription.

   ```powershell
   az login
   az account set --subscription xxxxx
   ```

1. Set the base name to the same value it was when you deployed the resources.

   ```powershell
   $BASE_NAME="<exact same value used before>"
   ```

1. Generate some variables to set context within your jump box.

   *The following variables align with the defaults in this deployment. Update them if you customized anything.*

   ```powershell
   $RESOURCE_GROUP="rg-chat-alz-baseline-${BASE_NAME}"
   $AI_FOUNDRY_NAME="aif${BASE_NAME}"
   $BING_CONNECTION_NAME="bingaiagent${BASE_NAME}"
   $AI_FOUNDRY_PROJECT_NAME="projchat"
   $MODEL_CONNECTION_NAME="agent-model"
   $BING_CONNECTION_ID="$(az cognitiveservices account show -n $AI_FOUNDRY_NAME -g $RESOURCE_GROUP --query 'id' --out tsv)/projects/${AI_FOUNDRY_PROJECT_NAME}/connections/${BING_CONNECTION_NAME}"
   $AI_FOUNDRY_AGENT_CREATE_URL="https://${AI_FOUNDRY_NAME}.services.ai.azure.com/api/projects/${AI_FOUNDRY_PROJECT_NAME}/assistants?api-version=2025-05-15-preview"

   echo $BING_CONNECTION_ID
   echo $MODEL_CONNECTION_NAME
   echo $AI_FOUNDRY_AGENT_CREATE_URL
   ```

1. Deploy the agent.

   *This step simulates deploying an AI agent through your pipeline from a network-connected build agent.*

   ```powershell
   # Use the agent definition on disk
   Invoke-WebRequest -Uri "https://github.com/Azure-Samples/azure-openai-chat-baseline-landing-zone/raw/refs/heads/main/agents/chat-with-bing.json" -OutFile "chat-with-bing.json"

   # Update to match your environment
   ${c:chat-with-bing-output.json} = ${c:chat-with-bing.json} -replace 'MODEL_CONNECTION_NAME', $MODEL_CONNECTION_NAME -replace 'BING_CONNECTION_ID', $BING_CONNECTION_ID

   # Deploy the agent
   az rest -u $AI_FOUNDRY_AGENT_CREATE_URL -m "post" --resource "https://ai.azure.com" -b @chat-with-bing-output.json

   # Capture the Agent's ID
   $AGENT_ID="$(az rest -u $AI_FOUNDRY_AGENT_CREATE_URL -m 'get' --resource 'https://ai.azure.com' --query 'data[0].id' -o tsv)"

   echo $AGENT_ID
   ```

### 3. Test the agent from the Azure AI Foundry portal in the playground. *Optional.*

Here you'll test your orchestration agent by invoking it directly from the Azure AI Foundry portal's playground experience. The Azure AI Foundry portal is only accessible from your private network, so you'll do this from your jump box.

*This step testing step is completely optional.*

1. Open the Azure portal to your subscription.

   You'll need to sign in to the Azure portal, and resolve any Entra ID Conditional Access policies on your account, if this is the first time you are connecting through the jump box.

1. Navigate to the Azure AI Foundry project named **projchat** in your resource group and open the Azure AI Foundry portal by clicking the **Go to Azure AI Foundry portal** button.

   This will take you directly into the 'Chat project'. Alternatively, you can find all your AI Foundry accounts and projects by going to <https://ai.azure.com> and you do not need to use the Azure portal to access them.

1. Click **Agents** in the side navigation.

1. Select the agent named 'Baseline Chatbot Agent'.

1. Click the **Try in playground** button.

1. Enter a question that would require grounding data through recent internet content, such as a notable recent event or the weather today in your location.

1. A grounded response to your question should appear on the UI.

### 4. Publish the chat front-end web app

Workloads build chat functionality into an application. Those interfaces usually call APIs which in turn call into your orchestrator. This implementation comes with such an interface. You'll deploy it to Azure App Service using its [run from package](https://learn.microsoft.com/azure/app-service/deploy-run-package) capabilities.

In a production environment, you use a CI/CD pipeline to:

- Build your web application
- Create the project zip package
- Upload the zip file to your Storage account from compute that is in or connected to the workload's virtual network.

For this deployment guide, you'll continue using your jump box to simulate part of that process.

1. Using the same PowerShell terminal session from previous steps, download the web UI.

   ```powershell
   Invoke-WebRequest -Uri https://github.com/Azure-Samples/azure-openai-chat-baseline-landing-zone/raw/refs/heads/main/website/chatui.zip -OutFile chatui.zip
   ```

1. Upload the web application to Azure Storage, where the web app will load the code from.

   ```powershell
   az storage blob upload -f chatui.zip --account-name "stwebapp${BASE_NAME}" --auth-mode login -c deploy -n chatui.zip
   ```

1. Update the app configuration to use the Azure AI Foundry project endpoint you deployed.

   ```powershell
   # Obtain the Azure AI Foundry project endpoint you deployed
   $AIFOUNDRY_PROJECT_ENDPOINT=$(az deployment group show -g "${RESOURCE_GROUP}" -n "ai-foundry-chat-lz-baseline-${BASE_NAME}" --query "properties.outputs.aiAgentProjectEndpoint.value" -o tsv)

   # Update the app configuration
   az webapp config appsettings set -n "app-${BASE_NAME}" -g $RESOURCE_GROUP --settings AIProjectEndpoint="${AIFOUNDRY_PROJECT_ENDPOINT}"
   ```

1. Update the app configuration to use the agent you deployed.

   ```powershell
   az webapp config appsettings set -n "app-${BASE_NAME}" -g $RESOURCE_GROUP --settings AIAgentId="${AGENT_ID}"
   ```

1. Restart the web app to load the site code and its updated configuation.

   ```powershell
   az webapp restart --name "app-${BASE_NAME}" --resource-group $RESOURCE_GROUP
   ```

### 5. Try it out! Test the deployed application that calls into the Azure AI Foundry Agent Service

This section will help you to validate that the workload is exposed correctly and responding to HTTP requests. This will validate that traffic is flowing through Application Gateway, into your Web App, and from your Web App, into the Azure AI Foundry agent API endpoint, which hosts the agent and its chat history. The agent will interface with Bing for grounding data and an OpenAI model for generative responses.

| :computer: | Unless otherwise noted, the following steps are all performed from your original workstation, not from the jump box. |
| :--------: | :------------------------- |

1. Get the public IP address of the Application Gateway.

   ```bash
   # Query the Azure Application Gateway Public IP
   APPGW_PUBLIC_IP=$(az network public-ip show -g $RESOURCE_GROUP -n "pip-$BASE_NAME" --query [ipAddress] --output tsv)
   echo APPGW_PUBLIC_IP: $APPGW_PUBLIC_IP
   ```

1. Create an `A` record for DNS.

   > :bulb: You can simulate this via a local hosts file modification.  Alternatively, you can add a real DNS entry for your specific deployment's application domain name if permission to do so.

   Map the Azure Application Gateway public IP address to the application domain name. To do that, please edit your hosts file (`C:\Windows\System32\drivers\etc\hosts` or `/etc/hosts`) and add the following record to the end: `${APPGW_PUBLIC_IP} www.${DOMAIN_NAME_APPSERV}` (e.g. `50.140.130.120  www.contoso.com`)

1. Browse to the site (e.g. <https://www.contoso.com>).

   > :bulb: It may take up to a few minutes for the App Service to start properly. Remember to include the protocol prefix `https://` in the URL you type in your browser's address bar. A TLS warning will be present due to using a self-signed certificate. You can ignore it or import the self-signed cert (`appgw.pfx`) to your user's trusted root store.

   Once you're there, ask your solution a question. Your question should involve something that would only be known if the RAG process included context from Bing such as recent weather or events.

## :broom: Clean up resources

Most Azure resources deployed in the prior steps will incur ongoing charges unless removed. This deployment typically costs over $88 per day, and more if you enabled Azure DDoS Protection. Promptly delete resources when you are done using them.

Additionally, a few of the resources deployed enter soft delete status which will restrict the ability to redeploy another resource with the same name or DNS entry; and might not release quota. It's best to purge any soft deleted resources once you are done exploring.

### Automated Cleanup (Recommended)

If you used the automated deployment scripts, you can use the saved variables:

```bash
# Source the saved deployment variables
source deployment-vars.env

# Delete the resource group (removes all resources)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Purge soft-deleted resources
az keyvault purge -n "kv-${BASE_NAME}" -l $LOCATION
az cognitiveservices account purge -g $RESOURCE_GROUP -l $LOCATION -n $AIFOUNDRY_NAME
```

### Manual Cleanup

If you deployed manually, use the following commands:

```bash
# Set your variables (replace with your actual values)
RESOURCE_GROUP="rg-chat-alz-baseline-<your-base-name>"
BASE_NAME="<your-base-name>"
LOCATION="<your-location>"
AIFOUNDRY_NAME="aif<your-base-name>"

# Delete the resource group
az group delete -n $RESOURCE_GROUP -y

# Purge soft-deleted resources
az keyvault purge -n "kv-${BASE_NAME}" -l $LOCATION
az cognitiveservices account purge -g $RESOURCE_GROUP -l $LOCATION -n $AIFOUNDRY_NAME
```

| :warning: | This will completely delete any data you may have included in this example. That data and this deployment will be unrecoverable. |
| :-------: | :------------------------- |

1. [Remove the Azure Policy assignments](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Compliance) scoped to the resource group. To identify those created by this implementation, look for ones that are prefixed with `[BASE_NAME] `.

## Production readiness changes

The infrastructure as code included in this repository has a few configurations that are made only to enable a smoother and less expensive deployment experience when you are first trying this implementation out. These settings are not recommended for production deployments, and you should evaluate each of the settings before deploying to production. Those settings all have a comment next to them that starts with `Production readiness change:`.

## Contributions

Please see our [Contributor guide](./CONTRIBUTING.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact <opencode@microsoft.com> with any additional questions or comments.

With :heart: from Azure Patterns & Practices, [Azure Architecture Center](https://azure.com/architecture).
