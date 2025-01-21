@description('Project name')
@minLength(3)
param projectName string

@description('Service name')
@minLength(3)
param serviceName string

@description('Azure region')
param location string

@description('Environment name')
@minLength(2)
param environment string

@description('Username who creates resources')
@minLength(2)
param createdBy string

@description('Container Registry name')
param containerRegistryName string

@description('Key Vault name')
param keyVaultName string

// Define RBAC role to pull image from Container Registry
var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Define RBAC role to get secret from Key Vault
var kvGetSecretRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// Create user assigned identity for container app
resource appUai 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'id-${projectName}-${serviceName}-${environment}'
  location: location
  tags: {
    createdBy: createdBy
    environment: environment
  }
}


// Get existing container registry by name
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: containerRegistryName
}

// Add RBAC role for user assigned inentity to pull image from Container Registry
resource appUaiRegistryRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, appUai.id, acrPullRole)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole
    principalId: appUai.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


// Get existing Key Vault by name
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Add RBAC role for user assigned inentity to get secret from Key Vault
resource appUaiKeyVaultRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appUai.id, kvGetSecretRole)
  scope: keyVault
  properties: {
    roleDefinitionId: kvGetSecretRole
    principalId: appUai.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output appUaiName string = appUai.name
