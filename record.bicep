param privateDnsZoneName string
param recordName string
param ipv4Address string

resource resRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateDnsZoneName}/${recordName}'
  properties: {
    ttl: 10
    aRecords: [
      {
        ipv4Address: ipv4Address
      }
    ]
  }
}
