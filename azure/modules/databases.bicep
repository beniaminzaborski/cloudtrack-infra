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

@description('The Postgres database administrator username')
param dbAdminLogin string

@description('The Postgres database administrator password')
@secure()
param dbAdminPassword string


resource postgres 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'psql-${projectName}-${environment}'
  location: location
  sku: {
    name: 'B_Gen5_1'
    tier: 'Basic'
  }
  tags: {
    environment: environment
    createdBy: createdBy
  }
  properties: {
    administratorLogin: dbAdminLogin
    administratorLoginPassword: dbAdminPassword
    createMode: 'Default'
    version: '11'
    sslEnforcement: 'Enabled'
    publicNetworkAccess: 'Enabled'
  }
}

resource postgresFirewallRules 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: postgres
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource competDB 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: '${projectName}_compet'
  parent: postgres
}

resource kvAdminDbPostgresConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}/ConnectionString-${projectName}-Compet-Postgres'
  properties: {
    value: 'Server=${postgres.name}.postgres.database.azure.com;Database=${competDB.name};Port=5432;Ssl Mode=Require;Trust Server Certificate=true;User Id=${dbAdminLogin}@${postgres.name};Password=${dbAdminPassword};'
  }
}

resource regstrDB 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  name: 'fott_registration'
  parent: postgres
}

resource kvRegistrDbPostgresConnString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kv-${projectName}-${environment}/ConnectionString-${projectName}-Regstr-Postgres'
  properties: {
    value: 'Server=${postgres.name}.postgres.database.azure.com;Database=${regstrDB.name};Port=5432;Ssl Mode=Require;Trust Server Certificate=true;User Id=${dbAdminLogin}@${postgres.name};Password=${dbAdminPassword};'
  }
}
