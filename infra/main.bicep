targetScope = 'subscription'

@description('Environment name (e.g., dev, test, prod)')
@minLength(1)
@maxLength(10)
param environmentName string = 'dev'

@description('Primary location for all resources')
param location string = 'westus3'

@description('Application name prefix')
@minLength(1)
@maxLength(10)
param appName string = 'zavastore'

@description('Docker image tag to deploy')
param dockerImageTag string = 'latest'

@description('Resource group name')
var resourceGroupName = 'rg-${appName}-${environmentName}-${location}'

@description('Common tags for all resources')
var tags = {
  Environment: environmentName
  Application: appName
  ManagedBy: 'AzureDeveloperCLI'
}

// Resource naming convention
var acrName = replace('acr${appName}${environmentName}${location}', '-', '')
var appServicePlanName = 'asp-${appName}-${environmentName}-${location}'
var webAppName = 'app-${appName}-${environmentName}-${location}'
var appInsightsName = 'appi-${appName}-${environmentName}-${location}'
var aiHubName = 'aih-${appName}-${environmentName}-${location}'
var storageAccountName = replace('st${appName}${environmentName}${take(location, 6)}', '-', '')
var keyVaultName = 'kv-${appName}-${environmentName}-${take(location, 6)}'

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Application Insights (deployed first as it's needed by AI Hub)
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  scope: rg
  params: {
    appInsightsName: appInsightsName
    location: location
    tags: tags
  }
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    acrName: acrName
    location: location
    acrSku: 'Basic'
    tags: tags
  }
}

// App Service Plan
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  scope: rg
  params: {
    appServicePlanName: appServicePlanName
    location: location
    sku: 'B1'
    tags: tags
  }
}

// Web App (with managed identity)
module webApp 'modules/webApp.bicep' = {
  name: 'webApp'
  scope: rg
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.loginServer
    dockerImageTag: dockerImageTag
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Role Assignment: Grant AcrPull to Web App's managed identity
module roleAssignment 'modules/roleAssignment.bicep' = {
  name: 'roleAssignment'
  scope: rg
  params: {
    acrId: acr.outputs.acrId
    principalId: webApp.outputs.principalId
  }
}

// AI Hub (Microsoft Foundry)
module aiHub 'modules/aiHub.bicep' = {
  name: 'aiHub'
  scope: rg
  params: {
    aiHubName: aiHubName
    location: location
    storageAccountName: storageAccountName
    keyVaultName: keyVaultName
    appInsightsId: appInsights.outputs.appInsightsId
    tags: tags
  }
}

// Outputs
@description('Resource Group Name')
output resourceGroupName string = rg.name

@description('ACR Login Server')
output acrLoginServer string = acr.outputs.loginServer

@description('ACR Name')
output acrName string = acr.outputs.acrName

@description('Web App Default Hostname')
output webAppHostname string = webApp.outputs.defaultHostname

@description('Web App Name')
output webAppName string = webApp.outputs.webAppName

@description('Application Insights Connection String')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('AI Hub Name')
output aiHubName string = aiHub.outputs.aiHubName

@description('Web App URL')
output webAppUrl string = 'https://${webApp.outputs.defaultHostname}'
