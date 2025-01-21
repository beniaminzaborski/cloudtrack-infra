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

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${projectName}-${environment}'
  location: location
  tags: {
    createdBy: createdBy
    environment: environment
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${projectName}-${environment}'
  location: location
  tags: {
    environment: environment
    createdBy: createdBy
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    ImmediatePurgeDataOn30Days: true
    RetentionInDays: 30
  }
}

resource kvAppInsightsConnString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'kv-${projectName}-${environment}/ConnectionString-${projectName}-AppInsights'
  properties: {
    value: applicationInsights.properties.ConnectionString
  }
}

output logAnalyticsName string = logAnalytics.name
