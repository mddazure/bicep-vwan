param frLocation string = 'francecentral'
param ukLocation string = 'uksouth'
param deployEr bool = false
@secure()
param erAuthKey string = ''
@secure()
param erCircuitId string = ''

///////////////////////////////VWAN///////////////////////////////////////////////////
// Virtual Wan master
resource vwan 'Microsoft.Network/virtualWans@2020-08-01' = {
  name: 'vwan-lab'
  location: frLocation
  properties: {
  }
}

// vHub FRANCE CENTRAL
resource vhubfrc 'Microsoft.Network/virtualHubs@2020-08-01' = {
  name: 'h-frc'
  location: frLocation
  properties: {
    addressPrefix: '192.168.10.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

//////////////////////////////////////ROUTE TABLES////////////////////////////////////////////
resource frcRtNva 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: 'rtNva'
  parent: vhubfrc
  properties: {
    routes: [
    ]
  }
}

resource frcRtVnet 'Microsoft.Network/virtualHubs/hubRouteTables@2020-08-01' = {
  name: 'rtVnet'
  parent: vhubfrc
  dependsOn: [
    [
      vhubErGw
    ]
    [
      frcVnet4Connection
    ]
  ]
  properties: {
    routes: [
      {
        destinations: [
          '192.168.2.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toOnPrem'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.12.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toVnet7'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '192.168.13.0/24'
        ]
        destinationType: 'CIDR'
        name: 'toVnet8'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '0.0.0.0/0'
        ]
        destinationType: 'CIDR'
        name: 'toInternet'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
      {
        destinations: [
          '128.0.0.0/1'
        ]
        destinationType: 'CIDR'
        name: 'toInternet'
        nextHop: resourceId('Microsoft.Network/virtualHubs/hubVirtualNetworkConnections', vhubfrc.name, 'frc-vnet4')
        nextHopType: 'ResourceId'
      }
    ]
  }
}

//vHub default route table
resource frcRtDefault 'Microsoft.Network/virtualHubs/hubRouteTables@2020-11-01' = {
  name: 'defaultRouteTable'
  parent: vhubfrc
  dependsOn: [
    [
      vhubErGw
    ]
    [
      frcVnet4Connection
    ]
  ]
  properties: {
    routes: [
      {
        destinations: [
          '0.0.0.0/0'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toInternet'
      }
      {
        destinations: [
          '192.168.12.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toVnet7'
      }
      {
        destinations: [
          '192.168.13.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toVnet8'
      }
      {
        destinations: [
          '192.168.14.0/24'
        ]
        destinationType: 'CIDR'
        nextHop: frcVnet4Connection.id
        nextHopType: 'ResourceId'
        name: 'toVnet3'
      }
    ]
  }
}

////////////////////////////////////VNET TO VHUB//////////////////////////////////////////////
// FRC - PEERING TO VHUB
// FRC - NVA VNET to VWAN FRC HUB CONNECTION
resource frcVnet4Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: frcVnet4.name
  parent: vhubfrc
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet4.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'rtNva')
      }
      propagatedRouteTables: {
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'rtVnet')
          }
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'defaultRouteTable')
          }
        ]
      }
      vnetRoutes: {
        staticRoutes: [
          {
            addressPrefixes: [
              '192.168.2.0/24'
            ]
            name: 'toOnPrem'
            nextHopIpAddress: vmNvaFrc.outputs.nicPrivateIp
          }
          {
            addressPrefixes: [
              '0.0.0.0/0'
            ]
            name: 'toInternet'
            nextHopIpAddress: vmNvaFrc.outputs.nicPrivateIp
          }
          {
            addressPrefixes: [
              '192.168.12.0/24'
            ]
            name: 'toVnet7'
            nextHopIpAddress: vmNvaFrc.outputs.nicPrivateIp
          }
          {
            addressPrefixes: [
              '192.168.13.0/24'
            ]
            name: 'toVnet8'
            nextHopIpAddress: vmNvaFrc.outputs.nicPrivateIp
          }
        ]
      }
    }
  }
}

// FRC - NON NVA VNET to VWAN FRC HUB CONNECTION
resource frcVnet3Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: frcVnet3.name
  parent: vhubfrc
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet3.outputs.vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'rtVnet')
      }
      propagatedRouteTables: {
        ids: [
          {
            id: frcRtVnet.id
          }
          {
            id: frcRtNva.id
          }
        ]
      }
    }
    enableInternetSecurity: true
  }
}
// END OF PEERING TO VHUB

///////////////////////////////////////GW S2S/P2S/ER///////////////////////////////////////////
// Express Route Scale unit in FRC
resource vhubErGw 'Microsoft.Network/expressRouteGateways@2020-08-01' = if(deployEr) {
  name: 'gw-frc-er'
  location: frLocation
  properties: {
    virtualHub: {
      id: vhubfrc.id
    }
    autoScaleConfiguration: {
      bounds: {
        min: 1
      }
    }
  }
  resource erCircuit 'expressRouteConnections@2020-08-01' = {
    name: 'con-ldn-er'
    properties: {
      authorizationKey: erAuthKey
      expressRouteCircuitPeering: {
        id: erCircuitId
      }
      routingConfiguration: {
        associatedRouteTable: {
          id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'defaultRouteTable')
        }
        propagatedRouteTables: {
          ids: [
            {
              id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'rtNva')
            }
            {
              id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhubfrc.name, 'defaultRouteTable')
            }
          ]
        }
      }
    }
  }
}

// FRC - NVA VNET
module frcVnet4 'vnet.bicep' = {
  name: 'frc-vnet4'
  params: {
    addressPrefix: '192.168.11.0/28'
    addressPrefixBastion: '192.168.11.32/27'
    addressSpace: '192.168.11.0/24'
    vnetName: 'frc-vnet4'
    location: frLocation
  }
}
module frcVnet4Bastion 'bastion.bicep' = {
  dependsOn: [
    [
      frcVnet4
    ]
  ]
  name: 'frc-vnet4-bastion'
  params: {
    bastionName: 'frc-vnet4-bastion'
    vnetName: 'frc-vnet4'
    location: frLocation
    bastionPubIpName: 'frc-vnet4-bastion-pubIp'
  }
}

// FRC - NON NVA VNET PEERED TO NVA VNET
module frcVnet7 'vnet.bicep' = {
  name: 'frc-vnet7'
  params: {
    addressPrefix: '192.168.12.0/28'
    addressPrefixBastion: '192.168.12.32/27'
    addressSpace: '192.168.12.0/24'
    vnetName: 'frc-vnet7'
    location: frLocation
    routeTableId: nonNvaVnetRt.id
  }
}
module frcVnet7Bastion 'bastion.bicep' = {
  dependsOn: [
    [
      frcVnet7
    ]
  ]
  name: 'frc-vnet7-bastion'
  params: {
    bastionName: 'frc-vnet7-bastion'
    vnetName: 'frc-vnet7'
    location: frLocation
    bastionPubIpName: 'frc-vnet7-bastion-pubIp'
  }
}

// FRC - NON NVA VNET PEERED TO NVA VNET
module frcVnet8 'vnet.bicep' = {
  name: 'frc-vnet8'
  params: {
    addressPrefix: '192.168.13.0/28'
    addressPrefixBastion: '192.168.13.32/27'
    addressSpace: '192.168.13.0/24'
    vnetName: 'frc-vnet8'
    location: frLocation
    routeTableId: nonNvaVnetRt.id
  }
}

// FRC - UDR FOR NON NVA VNET PEERED TO NVA VNET
resource nonNvaVnetRt 'Microsoft.Network/routeTables@2020-11-01' = {
  name: 'frc-vnet7-vnet8-rt'
  location: frLocation
  properties: {
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: vmNvaFrc.outputs.nicPrivateIp
          nextHopType:'VirtualAppliance'
        }
      }
    ]
  }
}

// FRC - NON NVA VNET PEERED TO VHUB FRC
module frcVnet3 'vnet.bicep' = {
  name: 'frc-vnet3'
  params: {
    addressPrefix: '192.168.14.0/28'
    addressPrefixBastion: '192.168.14.32/27'
    addressSpace: '192.168.14.0/24'
    vnetName: 'frc-vnet3'
    location: frLocation
  }
}
module frcVnet3Bastion 'bastion.bicep' = {
  dependsOn: [
    [
      frcVnet3
    ]
  ]
  name: 'frc-vnet3-bastion'
  params: {
    bastionName: 'frc-vnet3-bastion'
    vnetName: 'frc-vnet3'
    location: frLocation
    bastionPubIpName: 'frc-vnet3-bastion-pubIp'
  }
}

// FRC - PEERINGS //

resource vnet4Vnet7Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet4.name}/vnet4toVnet7'
  parent: frcVnet4
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet7.outputs.vnetId
    }
  }
}

resource vnet7Vnet4Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet7.name}/vnet7toVnet4'
  parent: frcVnet7
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet4.outputs.vnetId
    }
  }
}

resource vnet4Vnet8Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet4.name}/vnet4toVnet8'
  parent: frcVnet4
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet8.outputs.vnetId
    }
  }
}

resource vnet8Vnet4Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${frcVnet8.name}/vnet8toVnet4'
  parent: frcVnet8
  properties: {
    remoteVirtualNetwork: {
      id: frcVnet4.outputs.vnetId
    }
  }
}

// END OF PEERINGS



// VWAN UKS vHub
resource vhubuks 'Microsoft.Network/virtualHubs@2020-08-01' = {
  name: 'h-uks'
  location: ukLocation
  properties: {
    addressPrefix: '192.168.20.0/24'
    sku: 'Standard'
    virtualWan: {
      id: vwan.id
    }
  }
}

// UKS - NVA VNET
module uksVnet2 'vnet.bicep' = {
  name: 'uks-vnet2'
  dependsOn: [
    [
      uksVnet1Connection
    ]
  ]
  params: {
    addressPrefix: '192.168.21.0/28'
    addressPrefixBastion: '192.168.21.32/27'
    addressSpace: '192.168.21.0/24'
    vnetName: 'uks-vnet2'
    location: ukLocation
  }
}
module uksVnet2Bastion 'bastion.bicep' = {
  dependsOn: [
    [
      uksVnet2
    ]
  ]
  name: 'uks-vnet2-bastion'
  params: {
    bastionName: 'uks-vnet2-bastion'
    vnetName: 'uks-vnet2'
    location: ukLocation
    bastionPubIpName: 'uks-vnet2-bastion-pubIp'
  }
}
// UKS - NON NVA VNET PEERED TO NVA VNET
module uksVnet5 'vnet.bicep' = {
  name: 'uks-vnet5'
  params: {
    addressPrefix: '192.168.22.0/28'
    addressPrefixBastion: '192.168.22.32/27'
    addressSpace: '192.168.22.0/24'
    vnetName: 'uks-vnet5'
    location: ukLocation
  }
}
module uksVnet5Bastion 'bastion.bicep' = {
  dependsOn: [
    [
      uksVnet5
    ]
  ]
  name: 'uks-vnet5-bastion'
  params: {
    bastionName: 'uks-vnet5-bastion'
    vnetName: 'uks-vnet5'
    location: ukLocation
    bastionPubIpName: 'uks-vnet5-bastion-pubIp'
  }
}

// UKS - NON NVA VNET PEERED TO NVA VNET
module uksVnet6 'vnet.bicep' = {
  name: 'uks-vnet6'
  params: {
    addressPrefix: '192.168.23.0/28'
    addressPrefixBastion: '192.168.23.32/27'
    addressSpace: '192.168.23.0/24'
    vnetName: 'uks-vnet6'
    location: ukLocation
  }
}

// UKS - NON NVA VNET PEERED TO VHUB UKS
module uksVnet1 'vnet.bicep' = {
  name: 'uks-vnet1'
  params: {
    addressPrefix: '192.168.24.0/28'
    addressPrefixBastion: '192.168.24.32/27'
    addressSpace: '192.168.24.0/24'
    vnetName: 'uks-vnet1'
    location: ukLocation
  }
}
module uksVnet1Bastion 'bastion.bicep' = {
  dependsOn: [
    [
      uksVnet1
    ]
  ]
  name: 'uks-vnet1-bastion'
  params: {
    bastionName: 'uks-vnet1-bastion'
    vnetName: 'uks-vnet1'
    location: ukLocation
    bastionPubIpName: 'uks-vnet1-bastion-pubIp'
  }
}

// UKS - PEERINGS //

resource uksVnet2Vnet5Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet2.name}/vnet2toVnet5'
  parent: uksVnet2
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet5.outputs.vnetId
    }
  }
}

resource uksVnet5Vnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet5.name}/vnet5toVnet2'
  parent: uksVnet5
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet2.outputs.vnetId
    }
  }
}

resource uksVnet2Vnet6Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet2.name}/vnet2ToVnet6'
  parent: uksVnet2
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet6.outputs.vnetId
    }
  }
}

resource uksVnet6Vnet2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${uksVnet6.name}/vnet6toVnet2'
  parent: uksVnet6
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet2.outputs.vnetId
    }
  }
}

// END OF PEERINGS


// UKS - PEERING TO VHUB
// UKS - NVA VNET to VWAN FRC HUB CONNECTION
resource uksVnet2Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: uksVnet2.name
  parent: vhubuks
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet2.outputs.vnetId
    }
  }
}

// UKS - NON NVA VNET to VWAN UKS HUB CONNECTION
resource uksVnet1Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-08-01' = {
  name: uksVnet1.name
  parent: vhubuks
  properties: {
    remoteVirtualNetwork: {
      id: uksVnet1.outputs.vnetId
    }
  }
}
// END OF PEERING TO VHUB

// Express Route circuit to FRC

// VMs
// FRC - NVA
module vmNvaFrc 'vm.bicep' = {
  name: 'frc-nva'
  params: {
    location: frLocation
    subnetId: frcVnet4.outputs.subnetId
    vmName: 'frc-nva'
    enableForwarding: true
    createPublicIpNsg: true
    enableCloudInit: true
    createNsg: true
  }
}

// FRC - NON NVA VM IN FAR SPOKE0 PEERED TO NVA VNET
module frcVmVnet7 'vm.bicep' = {
  name: 'frc-vm7'
  params: {
    location: frLocation
    subnetId: frcVnet7.outputs.subnetId
    vmName: 'frc-vm7'
    enableForwarding: false
  }
}


// FRC - NON NVA VM IN SPOKE0 PEERED TO VHUB FRC
module vmSpoke0Frc 'vm.bicep' = {
  name: 'frc-vm3'
  params: {
    location: frLocation
    subnetId: frcVnet3.outputs.subnetId
    vmName: 'frc-vm3'
    enableForwarding: false
  }
}


// UKS - NON NVA VM IN SPOKE0 PEERED TO VHUB UKS
module vmSpoke0Uks 'vm.bicep' = {
  name: 'uks-vm1'
  params: {
    location: ukLocation
    subnetId: uksVnet1.outputs.subnetId
    vmName: 'uks-vm1'
    enableForwarding: false
  }
}

// UKS - NVA
module vmNvaUks 'vm.bicep' = {
  name: 'uks-nva'
  params: {
    location: ukLocation
    subnetId: uksVnet2.outputs.subnetId
    vmName: 'vm-nva-uks'
    enableForwarding: true
  }
}

// UKS - NON NVA VM IN FAR SPOKE0 PEERED TO NVA VNET
module uksVmVnet5 'vm.bicep' = {
  name: 'uks-vm5'
  params: {
    location: ukLocation
    subnetId: uksVnet5.outputs.subnetId
    vmName: 'vm-spoke0-0-uks'
    enableForwarding: false
  }
}
// END OF VMs
