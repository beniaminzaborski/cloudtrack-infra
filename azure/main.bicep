@description('Environment name')
@allowed(['dev', 'uat', 'prod'])
param environment string

@description('Azure region')
param location string

@description('The Postgres database administrator username')
param dbAdminLogin string = 'postgres'

@description('The Postgres database administrator password')
@secure()
param dbAdminPassword string

var projectName = 'cloudtrack'
var createdBy = 'Beniamin'
targetScope = 'subscription'

var isProdResourceGroup = environment == 'uat' || environment == 'prod'
var envResourceGroupSuffix = isProdResourceGroup ? 'prod' : 'nonprod'
var envResourceGroupName = 'rg-${projectName}-${envResourceGroupSuffix}'

resource envResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: envResourceGroupName
  location: location
}

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistryModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    isProdResourceGroup: isProdResourceGroup
    createdBy: createdBy
  }
}

module vaults 'modules/vaults.bicep' = {
  name: 'vaultModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
}

module observability 'modules/observability.bicep' = {
  name: 'observabilityModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
   ]
}

module databases 'modules/databases.bicep' = {
  name: 'databaseModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    dbAdminLogin: dbAdminLogin
    dbAdminPassword: dbAdminPassword
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
  ]
}

module messaging 'modules/messaging.bicep' = {
  name: 'messagingModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    environment: environment
    createdBy: createdBy
  }
  dependsOn: [
    vaults
  ]   
}

module appsEnv 'modules/container-apps-env.bicep' = {
  name: 'appsEnvModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    logAnalyticsName: observability.outputs.logAnalyticsName
    environment: environment
    createdBy: createdBy
  }
}

module comptAppUai 'modules/container-app-id.bicep' = {
  name: 'competAppUaiModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    serviceName: 'compt'
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

module comptApp 'modules/container-app-compt.bicep' = {
  name: 'competAppModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    appsEnvName: appsEnv.outputs.appsEnvName
    appUaiName: comptAppUai.outputs.appUaiName
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

module regstrAppUai 'modules/container-app-id.bicep' = {
  name: 'regstrAppUaiModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    serviceName: 'regstr'
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

module regstrApp 'modules/container-app-regstr.bicep' = {
  name: 'regstrAppModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    appsEnvName: appsEnv.outputs.appsEnvName
    appUaiName: regstrAppUai.outputs.appUaiName
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}
