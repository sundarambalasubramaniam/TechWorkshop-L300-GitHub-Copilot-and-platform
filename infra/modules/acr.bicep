@description('Name of the Azure Container Registry')
param acrName string

@description('Location for the ACR')
param location string = resourceGroup().location

@description('SKU for the ACR')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Tags to apply to the ACR')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  tags: tags
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

@description('ACR login server')
output loginServer string = acr.properties.loginServer

@description('ACR resource ID')
output acrId string = acr.id

@description('ACR name')
output acrName string = acr.name
