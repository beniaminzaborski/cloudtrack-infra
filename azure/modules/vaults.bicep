@description('Project name')
@minLength(3)
param projectName string

@description('Azure region')
param location string

@description('Environment name')
@minLength(2)
param environment string

@description('Username who creates resources')
@minLength(2)
param createdBy string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-${projectName}-${environment}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

output keyVaultName string = keyVault.name
