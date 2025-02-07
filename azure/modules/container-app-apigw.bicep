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

var serviceName = 'apigw'

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
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
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
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      secrets: [
        {
          name: 'connectionstrings-applicationinsights-kv'
          keyVaultUrl: 'https://${keyVault.name}.vault.azure.net/secrets/ConnectionString-${projectName}-AppInsights'
          identity: appUai.id
        }
      ]
      ingress: {
        external: true
        targetPort: 8080
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          identity: appUai.id
          server: containerRegistry.properties.loginServer
        }
      ]
      activeRevisionsMode: 'Single'
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
              name: 'ConnectionStrings__ApplicationInsights'
              secretRef: 'connectionstrings-applicationinsights-kv'
            }
            {
              name: 'ReverseProxy__Clusters__CompetCluster__Destinations__default__Address'
              value: 'http://ca-cloudtrack-compet-${environment}'
            }
            {
              name: 'ReverseProxy__Clusters__RegstrCluster__Destinations__default__Address'
              value: 'http://ca-cloudtrack-regstr-${environment}'
            }
          ]
          resources: {
            cpu: json('.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-requests'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}
