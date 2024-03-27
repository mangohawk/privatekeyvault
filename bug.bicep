targetScope = 'resourceGroup'

param location string

var containerInstanceSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkCompute.name, 'snet-key-compute-prod')

// Managed identity for deployment scripts to access requires resources
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-drift-prod'
  location: location
}

// Built-in Storage File Data Privileged Contributor Role Definition
resource storageFileDataPrivilegedContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
  scope: tenant()
}

// Built-in Reader Role Definition
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: tenant()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

// Built-in Key Vault Crypto Officer
resource keyVaultCryptoOfficerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: tenant()
  name: '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
}

// Role Assignment for Key Vault Secrets Officer
resource keyVaultCryptoOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultCryptoOfficerRoleDefinition.id, managedIdentity.id, keyVault.id)
  scope: keyVault
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: keyVaultCryptoOfficerRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment for Storage File Data Privileged Contributor
resource storageFileDataPrivilegedContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageFileDataPrivilegedContributorRoleDefinition.id, managedIdentity.id, storageAccount.id)
  scope: storageAccount
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: storageFileDataPrivilegedContributorRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment for Reader
resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(readerRoleDefinition.id, managedIdentity.id)
  scope: resourceGroup()
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId: readerRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stdriftprodt63'
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    allowSharedKeyAccess: true //Required for deploymentscripts
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: containerInstanceSubnetId
        }
      ]
    }
  }
}

// KeyVault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-key-test'
  location: location
  properties: {
    accessPolicies: []
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enableSoftDelete: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: '1188723c-afcd-4eb9-ac34-258ee148baf0'
  }
}

// Keys
resource keys 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: 'testing'
  properties: {
    kty: 'RSA'
    attributes: {
      enabled: true
      exportable: false
    }
  }
}

// Virtual Network for Containers
resource virtualNetworkCompute 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: 'vnet-compute-prod'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.255.0/24'
      ]
    }
    subnets: [
      {
        name: 'snet-key-compute-prod'
        properties: {
          addressPrefix: '192.168.255.0/25'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
          delegations: [
            {
              name: 'container-delegation'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'snet-key-endpoint-prod'
        properties: {
          addressPrefix: '192.168.255.128/25'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

// Virtual Network for KeyVaults
resource virtualNetworkKeyvault 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: 'vnet-key-prod'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.250.0/24'
      ]
    }
    subnets: [
      {
        name: 'snet-key-endpoint-prod'
        properties: {
          addressPrefix: '192.168.250.128/25'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

//Private DNS Zone for Storage Accounts.
resource privateDnsZoneStorageAccounts 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  #disable-next-line no-hardcoded-env-urls
  name: 'privatelink.file.core.windows.net'
  location: 'global'
}

//Private DNS Zone for Key Vaults.
resource privateDnsZoneKeyVaults 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  #disable-next-line no-hardcoded-env-urls
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

//Virtual Network Link for Storage Accounts.
resource virtualNetworkLinkStorageAccounts 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: uniqueString(virtualNetworkCompute.name)
  parent: privateDnsZoneStorageAccounts
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkCompute.id
    }
  }
}

//Virtual Network Link for Key Vaults.
resource virtualNetworkLinkKeyVaults 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: uniqueString(virtualNetworkCompute.name)
  parent: privateDnsZoneKeyVaults
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkCompute.id
    }
  }
}

//Network Security Group for the virtual networks.
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-avd-prod'
  location: location
  properties: {
    flushConnection: false
    securityRules: []
  }
}

// Private Endpoint for Storage Account
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-${storageAccount.name}'
  location: location
  properties: {
   privateLinkServiceConnections: [
     {
       name: storageAccount.name
       properties: {
         privateLinkServiceId: storageAccount.id
         groupIds: [
           'file'
         ]
       }
     }
   ]
   customNetworkInterfaceName: 'nic-${storageAccount.name}'
   subnet: {
    id: virtualNetworkCompute.properties.subnets[1].id
   }
  }
}

resource privateEndpointKeyVault 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-${keyVault.name}'
  location: location
  properties: {
   privateLinkServiceConnections: [
     {
       name: keyVault.name
       properties: {
         privateLinkServiceId: keyVault.id
         groupIds: [
           'vault'
         ]
       }
     }
   ]
   customNetworkInterfaceName: 'nic-${keyVault.name}'
   subnet: {
    id: virtualNetworkKeyvault.properties.subnets[0].id
   }
  }
}

// Module to get the current IP of the network interface of the Private Endpoint.
module storageAccountIP 'ip.bicep' = {
  name: 'deployment-ip'
  params: {
    nicName: last(split(privateEndpoint.properties.networkInterfaces[0].id, '/'))
  }
}

// Module to get the current IP of the network interface of the Private Endpoint.
module keyvaultIP 'ip.bicep' = {
  name: 'deployment-ip2'
  params: {
    nicName: last(split(privateEndpointKeyVault.properties.networkInterfaces[0].id, '/'))
  }
}

// Module to create A record for the Private Endpoint.
module record './record.bicep' = {
  name: 'deployment-${privateEndpoint.name}-record'
  params: {
    privateDnsZoneName: privateDnsZoneStorageAccounts.name
    recordName: storageAccount.name
    ipv4Address: storageAccountIP.outputs.ip
    
  }
}

// Module to create A record for the Private Endpoint.
module record2 './record.bicep' = {
  name: 'deployment-${privateEndpointKeyVault.name}-record'
  params: {
    privateDnsZoneName: privateDnsZoneKeyVaults.name
    recordName: keyVault.name
    ipv4Address: keyvaultIP.outputs.ip
    
  }
}


// Module delay deployment for RBAC role to take effect.
module delay './delayscheduler.bicep' = {
  name: 'deployment-delayer'
  params: {
    userAssignedIdentities: managedIdentity.id
  }
}

resource deploymentScriptsPowershellUpload 'Microsoft.Resources/deploymentScripts@2023-08-01' = { 
  name: 'ds-upload-to-automation'
  dependsOn: [
    privateEndpoint
    record
    virtualNetworkPeerings1
    virtualNetworkPeerings2
  ]
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}' : {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    storageAccountSettings: {
      storageAccountName: storageAccount.name
    }
    containerSettings: {
      subnetIds: [
        {
          id: containerInstanceSubnetId
        }
      ]
    }
    azCliVersion: '2.54.0'
    retentionInterval: 'PT1H'
    timeout: 'PT5M'
    cleanupPreference: 'OnExpiration'
    scriptContent: '''
    az keyvault key show --vault-name kv-key-test --name testing --query key.kid --debug
    '''
  }
}

resource virtualNetworkPeerings1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'string'
  parent: virtualNetworkCompute
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: false
    doNotVerifyRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        '192.168.255.0/24'
      ]
    }
    remoteVirtualNetwork: {
      id: virtualNetworkKeyvault.id
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.250.0/24'
      ]
    }
    useRemoteGateways: false
  }
}

resource virtualNetworkPeerings2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'string'
  parent: virtualNetworkKeyvault
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: false
    doNotVerifyRemoteGateways: false
    remoteAddressSpace: {
      addressPrefixes: [
        '192.168.250.0/24'
      ]
    }
    remoteVirtualNetwork: {
      id: virtualNetworkCompute.id
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.255.0/24'
      ]
    }
    useRemoteGateways: false
  }
}

