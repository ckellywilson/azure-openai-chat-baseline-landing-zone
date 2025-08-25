# Azure MCP Server Integration

This workspace is configured to use Microsoft's official Azure MCP Server with GitHub Copilot.

## What is Azure MCP Server?

The Azure MCP Server uses the Model Context Protocol (MCP) to provide GitHub Copilot with direct access to your Azure resources, enabling context-aware AI assistance for Azure operations.

## Setup

The integration is automatically configured using `.vscode/mcp.json` following Microsoft's official documentation:

```json
{
  "servers": {
    "Azure MCP Server": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
```

## Usage

1. **Open GitHub Copilot Chat** in VS Code
2. **Enable Agent Mode** (click the agent icon)
3. **View available tools** (click the tools icon to see Azure MCP Server)
4. **Ask Azure questions** naturally:

### Example Prompts:
- "List my Azure resource groups"
- "Show me all storage accounts in my subscription"
- "Get details for my App Service resources"
- "List virtual machines in resource group 'rg-prod'"
- "Show me the configuration of my Key Vault"

## Authentication

- **Automatic**: If you're already authenticated with Azure CLI (`az login`), the MCP server uses those credentials
- **Browser Sign-in**: If not authenticated, Copilot will prompt you to sign in through your browser
- **Permissions**: Grant permissions when prompted by Copilot for specific operations

## What You Can Do

The Azure MCP Server provides comprehensive Azure resource management through natural language:

- **📋 List Resources**: Resource groups, storage accounts, VMs, databases, etc.
- **🔍 Get Details**: Detailed configuration and properties of specific resources
- **🏗️ Query Deployments**: Information about ARM/Bicep deployments
- **📊 Monitor Status**: Resource health and operational status
- **🔐 Access Management**: View access policies and permissions

## Prerequisites

- Azure account with active subscription
- GitHub Copilot extension in VS Code
- Azure resources you want to query (must already exist)
- Appropriate RBAC permissions for the resources you want to access

## Troubleshooting

### MCP Server Not Visible
1. Ensure `.vscode/mcp.json` exists and is properly formatted
2. Restart VS Code after making changes
3. Enable Agent Mode in GitHub Copilot Chat
4. Check that GitHub Copilot extensions are installed

### Authentication Issues
1. Try `az login` to authenticate with Azure CLI first
2. Allow browser popups for Azure authentication
3. Accept permission requests from Copilot
4. Verify you have proper RBAC permissions on Azure resources

### Performance
- The first query may be slower as `npx` downloads the latest Azure MCP server
- Subsequent queries will be faster as the server is cached locally

## Learn More

- [Official Microsoft Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-mcp-server/get-started/tools/visual-studio-code)
- [Azure MCP Server Tools Reference](https://learn.microsoft.com/en-us/azure/developer/azure-mcp-server/tools/)
- [GitHub Copilot Agent Mode Documentation](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)
