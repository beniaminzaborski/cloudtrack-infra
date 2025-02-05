@description('Project name')
@minLength(3)
param projectName string

@description('Azure region')
param location string

@description('Contaimer Apps Environment name')
param appsEnvName string

@description('User Assigned Identity name')
param appUaiName string

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

var serviceName = 'regstr-func'

// Get existsing UAI
resource appUai 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: appUaiName
}

// Get existing container registry by name
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: containerRegistryName
}

// Get existing Key Vault by name
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}


//Get existing Container Apps Environment by name
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: appsEnvName
}

// Dedicated Strorage Account for Azure Function App
resource storageAccountRegistrFuncApp 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${projectName}${substring(replace(serviceName, '-', ''), 0, 7)}${environment}'
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}

resource registrFuncApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'func-${projectName}-${serviceName}-${environment}'
  location: location
  kind: 'functionapp,linux,container,azurecontainerapps'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appUai.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    //keyVaultReferenceIdentity: keyVault.id
    siteConfig: {
      //linuxFxVersion: 'DOCKER|${containerRegistry.properties.loginServer}/${projectName}-${serviceName}:latest'
      // Only hardcoded works and this is by design! :)))
      linuxFxVersion: 'DOCKER|crcloudtracknonprod.azurecr.io/cloudtrack-regstr-func:latest'
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-${projectName}-AppInsights)'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountRegistrFuncApp.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccountRegistrFuncApp.listKeys().keys[0].value}'
        }        
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: containerRegistry.properties.loginServer
        }   
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistry.listCredentials().username
        } 
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistry.listCredentials().passwords[0].value
        }                        
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        // It does not work - set it manually
        {
          name: 'PostgresConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-${projectName}-${serviceName}-Postgres)'
        }
        // It does not work - set it manually
        {
          name: 'ServiceBusConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-${projectName}-ServiceBus)'
        }
      ]
    }
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
}
