@description('ACR resource ID')
param acrId string

@description('Principal ID to assign the role to')
param principalId string

@description('Role definition ID for AcrPull')
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, acrPullRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Role assignment resource ID')
output roleAssignmentId string = acrPullRoleAssignment.id
