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

// Container App Environment
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

// Competitions Container App
module competAppUai 'modules/container-app-id.bicep' = {
  name: 'competAppUaiModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    serviceName: 'compet'
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

module competApp 'modules/container-app-compet.bicep' = {
  name: 'competAppModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    appsEnvName: appsEnv.outputs.appsEnvName
    appUaiName: competAppUai.outputs.appUaiName
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

// Competitions Container App Job
module competJobAppUai 'modules/container-app-id.bicep' = {
  name: 'competJobAppUaiModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    serviceName: 'competjob'
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

module competJobApp 'modules/container-app-compet-job.bicep' = {
  name: 'competJobAppModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    appsEnvName: appsEnv.outputs.appsEnvName
    appUaiName: competJobAppUai.outputs.appUaiName
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

// Registrations Container App
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

// Registrations Container App Function
// module regstrFuncAppUai 'modules/container-app-id.bicep' = {
//   name: 'regstrFuncAppUaiModule'
//   scope: envResourceGroup
//   params: {
//     location: location
//     projectName: projectName
//     serviceName: 'regstr-func'
//     containerRegistryName: containerRegistry.outputs.containerRegistryName
//     keyVaultName: vaults.outputs.keyVaultName
//     environment: environment
//     createdBy: createdBy
//   }
// }

module regstrFuncApp 'modules/func-app-regstr.bicep' = {
  name: 'regstrFuncAppModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    appsEnvName: appsEnv.outputs.appsEnvName
    //appUaiName: regstrFuncAppUai.outputs.appUaiName
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

// API Gateway Container App
module apigwAppUai 'modules/container-app-id.bicep' = {
  name: 'apigwAppUaiModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    serviceName: 'apigw'
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}

module apigwApp 'modules/container-app-apigw.bicep' = {
  name: 'apigwAppModule'
  scope: envResourceGroup
  params: {
    location: location
    projectName: projectName
    appsEnvName: appsEnv.outputs.appsEnvName
    appUaiName: apigwAppUai.outputs.appUaiName
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    keyVaultName: vaults.outputs.keyVaultName
    environment: environment
    createdBy: createdBy
  }
}
