# Deployment Guide - ZavaStorefront Infrastructure

This guide provides step-by-step instructions for deploying the ZavaStorefront application infrastructure to Azure.

## Prerequisites Checklist

Before starting the deployment, ensure you have:

- [ ] Azure subscription with Contributor access
- [ ] Azure CLI installed (version 2.50.0+)
- [ ] Azure Developer CLI installed
- [ ] Appropriate quotas in westus3 for:
  - Azure Container Registry
  - App Service (B1 SKU)
  - Azure Machine Learning (for AI Hub)
  - Storage Accounts
  - Key Vault

## Deployment Steps

### Option 1: Quick Deployment with AZD (Recommended)

This is the fastest way to get started:

```bash
# 1. Navigate to repository root
cd TechWorkshop-L300-GitHub-Copilot-and-platform

# 2. Login to Azure
az login
azd auth login

# 3. Initialize AZD (first time only)
azd init

# 4. Set environment variables (optional, or accept defaults)
azd env set AZURE_LOCATION westus3
azd env set AZURE_ENV_NAME dev

# 5. Deploy everything (provision + deploy)
azd up
```

The `azd up` command will:
1. Create the resource group
2. Deploy all infrastructure using Bicep
3. Build the Docker image in ACR (cloud-based build)
4. Deploy the application to App Service
5. Display the application URL

### Option 2: Step-by-Step Deployment

For more control, deploy infrastructure and application separately:

```bash
# 1. Provision infrastructure only
azd provision

# 2. Note the outputs (ACR name, Web App name, etc.)
azd env get-values

# 3. Deploy application
azd deploy
```

### Option 3: Manual Deployment with Azure CLI

For complete control:

```bash
# 1. Set variables
LOCATION="westus3"
ENV_NAME="dev"
APP_NAME="zavastore"

# 2. Deploy Bicep template
az deployment sub create \
  --location $LOCATION \
  --template-file infra/main.bicep \
  --parameters environmentName=$ENV_NAME location=$LOCATION appName=$APP_NAME

# 3. Get resource names from outputs
RESOURCE_GROUP=$(az deployment sub show --name main --query properties.outputs.resourceGroupName.value -o tsv)
ACR_NAME=$(az deployment sub show --name main --query properties.outputs.acrName.value -o tsv)
WEB_APP_NAME=$(az deployment sub show --name main --query properties.outputs.webAppName.value -o tsv)

# 4. Build and push Docker image
az acr build \
  --registry $ACR_NAME \
  --image zava-storefront:latest \
  --file Dockerfile \
  ./src

# 5. Restart web app to pull new image
az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

# 6. Get application URL
az webapp show --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv
```

## Post-Deployment Verification

### 1. Verify Web Application

```bash
# Get the URL
APP_URL=$(azd env get-values | grep WEB_APP_URL | cut -d'=' -f2)

# Test the application
curl -I $APP_URL
```

Expected response: HTTP 200 OK

### 2. Verify Application Insights

```bash
# Get Application Insights name
AI_NAME=$(az deployment sub show --name main --query properties.outputs.appInsightsName.value -o tsv)

# Check if telemetry is being received
az monitor app-insights metrics show \
  --app $AI_NAME \
  --resource-group $RESOURCE_GROUP \
  --metric requests/count
```

### 3. Verify ACR Access

```bash
# Test that Web App can access ACR
az webapp show \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "identity.principalId" -o tsv

# Check role assignment
az role assignment list \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME
```

Should show AcrPull role assigned to the Web App's managed identity.

### 4. Access the Application

Open your browser and navigate to the Web App URL. You should see:
- Product catalog page
- Functional shopping cart
- No errors in the browser console

## Updating the Application

To deploy a new version:

```bash
# Method 1: Using AZD
azd deploy

# Method 2: Manual update
az acr build \
  --registry $ACR_NAME \
  --image zava-storefront:$(git rev-parse --short HEAD) \
  --file Dockerfile \
  ./src

az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
```

## Troubleshooting

### Issue: Web App shows "Container didn't respond"

**Solution:**
1. Check that ACR build completed successfully
2. Verify managed identity has AcrPull role
3. Check App Service logs:
   ```bash
   az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
   ```

### Issue: Application Insights not receiving data

**Solution:**
1. Verify connection string is set:
   ```bash
   az webapp config appsettings list \
     --name $WEB_APP_NAME \
     --resource-group $RESOURCE_GROUP \
     --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING']"
   ```
2. Restart the web app if needed

### Issue: ACR build fails

**Solution:**
1. Check Dockerfile syntax
2. Verify all project files are present in src/
3. Check ACR quota limits
4. Review build logs for specific errors

### Issue: Deployment fails with quota errors

**Solution:**
1. Check regional quotas:
   ```bash
   az vm list-usage --location westus3 -o table
   ```
2. Request quota increase if needed
3. Try a different region if westus3 has limitations

## GitHub Actions Deployment

To set up automated deployments:

1. **Create Azure AD App Registration**:
   ```bash
   az ad app create --display-name "GitHub-ZavaStore-Deploy"
   ```

2. **Configure federated credentials** (see infra/README.md for details)

3. **Set GitHub Secrets**:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

4. **Trigger deployment**: Push to main branch or manually trigger workflow

## Resource Cleanup

When you're done testing:

```bash
# Option 1: Using AZD
azd down --purge --force

# Option 2: Using Azure CLI
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

**Note**: This will delete ALL resources in the resource group. Make sure you have backups if needed.

## Cost Monitoring

To monitor costs:

```bash
# Get cost summary
az consumption usage list \
  --start-date $(date -d '7 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceName, 'zavastore')]" \
  -o table
```

Or use the Azure Portal:
1. Navigate to Cost Management + Billing
2. Filter by resource group: rg-zavastore-dev-westus3

## Next Steps

1. **Configure AI Models**: Deploy GPT-4 and Phi models in AI Hub
2. **Set up monitoring alerts**: Configure Application Insights alerts for errors and performance
3. **Enable staging slots**: Add a staging slot for zero-downtime deployments
4. **Custom domain**: Configure a custom domain name for the web app
5. **Scale up**: If needed, upgrade SKUs for production workloads

## Support and Documentation

- [Infra README](README.md) - Detailed infrastructure documentation
- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Web Apps for Containers](https://learn.microsoft.com/azure/app-service/quickstart-custom-container)
