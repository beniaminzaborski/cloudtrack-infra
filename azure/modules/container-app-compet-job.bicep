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

var serviceName = 'competjob'

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


// Create Container App
resource containerApp 'Microsoft.App/jobs@2024-10-02-preview' = {
  name: 'ca-${projectName}-${serviceName}-${environment}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appUai.id}': {}
    }
  }
  tags: {
    createdBy: createdBy
    environment: environment
  }
  properties: {
    environmentId: containerAppEnv.id
    configuration: {
      replicaTimeout: 360
      triggerType: 'Schedule'
      scheduleTriggerConfig: {
        // At 10:00 on every day-of-month.
        cronExpression: '0 10 */1 * *'
        parallelism: 1
      }
      secrets: [
        {
          name: 'connectionstrings-postgres-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-${projectName}-compet-Postgres'
          identity: appUai.id
        }
        {
          name: 'connectionstrings-azureservicebus-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-${projectName}-ServiceBus'
          identity: appUai.id
        }
        {
          name: 'connectionstrings-applicationinsights-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-${projectName}-AppInsights'
          identity: appUai.id
        }
      ]
      registries: [
        {
          identity: appUai.id
          server: containerRegistry.properties.loginServer
        }
      ]
    }
    template: {
      containers: [
        {
          name: '${projectName}-${serviceName}'
          image: '${containerRegistry.properties.loginServer}/${projectName}-${serviceName}:latest'
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Development'
            }
            {
              name: 'ConnectionStrings__Postgres'
              secretRef: 'connectionstrings-postgres-kv'
            }
            {
              name: 'ConnectionStrings__AzureServiceBus'
              secretRef: 'connectionstrings-azureservicebus-kv'
            }
            {
              name: 'ConnectionStrings__ApplicationInsights'
              secretRef: 'connectionstrings-applicationinsights-kv'
            }
          ]
          resources: {
            cpu: json('.25')
            memory: '0.5Gi'
          }
        }
      ]
    }
  }
}
