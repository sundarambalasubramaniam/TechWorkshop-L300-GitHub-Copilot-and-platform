# Azure Infrastructure for ZavaStorefront

This directory contains the Infrastructure as Code (IaC) templates for deploying the ZavaStorefront application to Azure using Bicep and Azure Developer CLI (AZD).

## Architecture Overview

The infrastructure provisions the following Azure resources in the `westus3` region:

- **Resource Group**: Container for all resources (`rg-zavastore-dev-westus3`)
- **Azure Container Registry (ACR)**: Stores Docker container images (Basic SKU)
- **App Service Plan**: Linux-based hosting plan for the web app (B1 SKU)
- **Web App**: Linux App Service (Web App for Containers) configured to pull from ACR
- **Application Insights**: Monitoring and diagnostics for the application
- **AI Hub**: Microsoft Foundry workspace for GPT-4 and Phi model access
- **Storage Account**: Required for AI Hub operations
- **Key Vault**: Secrets management for AI Hub

## Key Features

- **Managed Identity**: System-assigned managed identity for secure, password-less ACR access
- **RBAC Integration**: AcrPull role assignment automatically configured
- **Cloud-based Builds**: No local Docker required - builds run in ACR or GitHub Actions
- **Application Monitoring**: Integrated Application Insights for telemetry
- **AI Integration**: Microsoft Foundry for GPT-4 and Phi models in westus3

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   az --version
   az login
   ```

2. **Azure Developer CLI (AZD)**
   ```bash
   # Install AZD
   curl -fsSL https://aka.ms/install-azd.sh | bash
   
   # Or on Windows (PowerShell)
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   
   # Verify installation
   azd version
   ```

3. **Azure Subscription** with appropriate permissions:
   - Contributor role on the subscription
   - Ability to create resource groups and role assignments

## Deployment Options

### Option 1: Using Azure Developer CLI (Recommended)

The Azure Developer CLI (AZD) provides a streamlined deployment experience:

```bash
# 1. Initialize AZD (first time only)
azd init

# 2. Provision infrastructure
azd provision

# 3. Build and deploy the application
azd deploy

# Or do both in one command
azd up
```

The `azd provision` command will:
- Deploy all Bicep templates
- Create all Azure resources
- Configure role assignments
- Output important values (URLs, connection strings, etc.)

The `azd deploy` command will:
- Build the Docker image using `az acr build` (cloud-based build)
- Push the image to ACR
- Update the Web App to use the new image
- Restart the Web App

### Option 2: Using Azure CLI Directly

If you prefer to use Azure CLI directly:

```bash
# 1. Set variables
LOCATION="westus3"
ENV_NAME="dev"
APP_NAME="zavastore"
SUBSCRIPTION_ID="<your-subscription-id>"

# 2. Deploy the Bicep template
az deployment sub create \
  --location $LOCATION \
  --template-file infra/main.bicep \
  --parameters environmentName=$ENV_NAME location=$LOCATION appName=$APP_NAME

# 3. Get outputs
RESOURCE_GROUP=$(az deployment sub show \
  --name main \
  --query properties.outputs.resourceGroupName.value \
  --output tsv)

ACR_NAME=$(az deployment sub show \
  --name main \
  --query properties.outputs.acrName.value \
  --output tsv)

# 4. Build and push Docker image
az acr build \
  --registry $ACR_NAME \
  --image zava-storefront:latest \
  --file Dockerfile \
  ./src

# 5. The Web App will automatically pull the latest image
```

### Option 3: Using GitHub Actions

The repository includes a GitHub Actions workflow for automated deployments:

1. **Configure Azure Credentials**:
   
   Set up federated identity credentials for GitHub Actions:
   
   ```bash
   # Create Azure AD App Registration
   az ad app create --display-name "GitHub-ZavaStore-Deploy"
   
   # Get the app ID
   APP_ID=$(az ad app list --display-name "GitHub-ZavaStore-Deploy" --query "[0].appId" -o tsv)
   
   # Create service principal
   az ad sp create --id $APP_ID
   
   # Assign Contributor role
   az role assignment create \
     --role Contributor \
     --assignee $APP_ID \
     --scope /subscriptions/<subscription-id>
   
   # Configure federated credentials
   az ad app federated-credential create \
     --id $APP_ID \
     --parameters @- <<EOF
   {
     "name": "github-deploy",
     "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:your-org/your-repo:environment:dev",
     "audiences": ["api://AzureADTokenExchange"]
   }
   EOF
   ```

2. **Set GitHub Secrets**:
   
   In your GitHub repository, go to Settings → Secrets and variables → Actions, and add:
   - `AZURE_CLIENT_ID`: Application (client) ID
   - `AZURE_TENANT_ID`: Directory (tenant) ID
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID

3. **Trigger Deployment**:
   
   - Push to the `main` branch, or
   - Manually trigger the workflow from the Actions tab

## Infrastructure Modules

The infrastructure is organized into modular Bicep files:

- **`main.bicep`**: Main orchestration template
- **`modules/acr.bicep`**: Azure Container Registry
- **`modules/appServicePlan.bicep`**: App Service Plan (Linux)
- **`modules/webApp.bicep`**: Web App with managed identity and ACR integration
- **`modules/appInsights.bicep`**: Application Insights
- **`modules/aiHub.bicep`**: Microsoft Foundry (AI Hub) with supporting resources
- **`modules/roleAssignment.bicep`**: RBAC role assignment for AcrPull

## Configuration

Default parameters are defined in `main.bicepparam`:

```bicep
environmentName = 'dev'
location = 'westus3'
appName = 'zavastore'
dockerImageTag = 'latest'
```

To override parameters during deployment:

```bash
# Using AZD
azd provision --parameter environmentName=test

# Using Azure CLI
az deployment sub create \
  --template-file infra/main.bicep \
  --parameters environmentName=test location=eastus
```

## Post-Deployment

After successful deployment:

1. **Access the Web App**:
   ```bash
   # Get the Web App URL
   azd env get-values | grep WEB_APP_URL
   
   # Or using Azure CLI
   az webapp show \
     --name app-zavastore-dev-westus3 \
     --resource-group rg-zavastore-dev-westus3 \
     --query "defaultHostName" \
     --output tsv
   ```

2. **View Application Insights**:
   - Navigate to Azure Portal → Application Insights
   - View live metrics, logs, and performance data

3. **Access AI Hub**:
   - Navigate to Azure Portal → Machine Learning
   - Open the AI Hub workspace
   - Deploy GPT-4 and Phi models as needed

## Updating the Application

To deploy a new version of the application:

```bash
# Using AZD
azd deploy

# Or manually using Azure CLI
az acr build \
  --registry $ACR_NAME \
  --image zava-storefront:$(git rev-parse --short HEAD) \
  --file Dockerfile \
  ./src

az webapp restart \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP
```

## Cost Estimation

Approximate monthly costs for the dev environment (westus3):

| Resource | SKU | Est. Monthly Cost |
|----------|-----|-------------------|
| App Service Plan | B1 | ~$13 |
| Azure Container Registry | Basic | ~$5 |
| Application Insights | Pay-as-you-go | ~$5-10 |
| AI Hub | Basic | ~$0-50* |
| Storage Account | Standard LRS | ~$1-2 |
| Key Vault | Standard | ~$0.50 |
| **Total** | | **~$25-80/month** |

*AI Hub costs vary based on model usage and deployments

## Cleanup

To delete all resources:

```bash
# Using AZD
azd down --purge --force

# Or using Azure CLI
az group delete \
  --name rg-zavastore-dev-westus3 \
  --yes --no-wait
```

## Troubleshooting

### ACR Pull Failures

If the Web App cannot pull images from ACR:

```bash
# Verify managed identity
az webapp identity show \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3

# Verify role assignment
az role assignment list \
  --scope /subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3/providers/Microsoft.ContainerRegistry/registries/acrzavastoredwwestus3
```

### Application Insights Not Receiving Data

Ensure the connection string is configured:

```bash
az webapp config appsettings list \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING']"
```

### Logs and Diagnostics

View application logs:

```bash
# Stream logs
az webapp log tail \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3

# Download logs
az webapp log download \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Web Apps for Containers](https://learn.microsoft.com/azure/app-service/quickstart-custom-container)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Microsoft Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
