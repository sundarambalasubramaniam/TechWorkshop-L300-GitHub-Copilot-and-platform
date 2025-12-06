@description('Name of the AI Hub')
param aiHubName string

@description('Location for the AI Hub')
param location string = resourceGroup().location

@description('Tags to apply to the AI Hub')
param tags object = {}

@description('SKU name for the AI Hub')
param skuName string = 'Basic'

@description('Storage account name for AI Hub')
param storageAccountName string

@description('Key Vault name for AI Hub')
param keyVaultName string

@description('Application Insights resource ID')
param appInsightsId string

// Storage Account for AI Hub
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Key Vault for AI Hub
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
  }
}

// AI Hub (Azure Machine Learning workspace)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiHubName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuName
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: aiHubName
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: appInsightsId
    hbiWorkspace: false
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    managedNetwork: {
      isolationMode: 'Disabled'
    }
  }
}

@description('AI Hub resource ID')
output aiHubId string = aiHub.id

@description('AI Hub name')
output aiHubName string = aiHub.name

@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Key Vault name')
output keyVaultName string = keyVault.name
