param bastionName string
param vnetName string
param location string
param bastionPubIpName string

resource bastionPubIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: bastionPubIpName
  location: location
  sku: {
    name:'Standard'
    tier:'Regional'
  }
  properties:{
    publicIPAllocationMethod:'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2020-11-01' = {
  name: bastionName
  location: location
  dependsOn:[
    [
    bastionPubIp
    ]
  ]
  properties:{
    ipConfigurations:[
      {
        name:'ipconfig1'
        properties:{
          subnet:{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets',vnetName,'AzureBastionSubnet')
          } 
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIpAddresses', bastionPubIpName)
          }
        }
      }
    ]
  }
}
