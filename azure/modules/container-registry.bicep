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

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: 'cr${projectName}${environment}'
  location: location
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: true 
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

output containerRegistryName string =  containerRegistry.name
