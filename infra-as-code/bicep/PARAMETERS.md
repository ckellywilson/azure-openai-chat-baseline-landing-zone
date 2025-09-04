# Parameters File Management

## Files in this directory:

### ✅ Template Files (checked into git)
- `parameters.alz.template.json` - Template with placeholder values for ALZ deployments
- Contains placeholders like `YOUR-SUBSCRIPTION-ID`, `YOUR-NETWORKING-RG`, etc.

### ❌ Environment-Specific Files (NOT checked into git)  
- `parameters.alz.json` - Contains real subscription IDs and resource names
- `jumbox/parameters.json` - Contains actual network resource IDs
- `*.backup.*` - Backup files created during deployment

## Setup Process:

1. **Copy template to working file:**
   ```bash
   cp parameters.alz.template.json parameters.alz.json
   ```

2. **Update with your values:**
   - Replace `YOUR-SUBSCRIPTION-ID` with your actual subscription ID
   - Replace `YOUR-NETWORKING-RG` with your resource group name  
   - Replace `YOUR-SPOKE-VNET-NAME` with your VNet name
   - Update subnet address prefixes as needed

3. **Use setup script (recommended):**
   ```bash
   ./setup-parameters.sh
   ```
   This script will interactively help you configure the parameters.

## Security Note:

The `.gitignore` file ensures that environment-specific parameters files containing real subscription IDs and resource names are not committed to the repository. Always use the template files as your starting point for new environments.
