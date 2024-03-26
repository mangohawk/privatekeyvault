param name string

resource userAssignedIdentities 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: name
}

output arrayResult string = userAssignedIdentities.apiVersion
