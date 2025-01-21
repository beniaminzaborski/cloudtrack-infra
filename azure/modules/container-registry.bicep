@description('Project name')
@minLength(3)
param projectName string

@description('Azure region')
param location string

@description('Username who creates resources')
@minLength(2)
param createdBy string

@description('Informs if it is shared prod or nonprod resource group')
param isProdResourceGroup bool

var environment = isProdResourceGroup ? 'prod' : 'nonprod'

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
