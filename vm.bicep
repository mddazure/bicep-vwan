param vmName string
param location string
param subnetId string
param enableForwarding bool = false
param createPublicIpNsg bool = false
param createNsg bool = false
param enableCloudInit bool = false

module nic 'nic.bicep' = {
  name: '${vmName}-nic'
  params: {
    location: location
    nicName: '${vmName}-nic'
    subnetId: subnetId
    enableForwarding: enableForwarding
    createPublicIpNsg: createPublicIpNsg
    createNsg: createNsg
    vmName: vmName
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    osProfile: {
      customData: enableCloudInit ? 'I2luY2x1ZGUKaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2FsZXhhbmRyZXdlaXNzL2diYi1lbWVhLWxhYi9kZXZlbG9wL3Z3YW4tbGFiL2NvbmZpZy1maWxlcy92bS1udmEtZnJjLWNpLnRwbA==' : json('null')
      adminUsername: 'admin-lab'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/admin-lab/.ssh/authorized_keys'
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCchKVx9tfk5lTf1d6Una7gC5MkmPAj8RNq5p6w/6hWlcuo+uLBHLNLG59yIjOZqvumOf/XSP/tPpn+YtdU0E5XHZ5ZSR7Zw6ZNBqiQOBYx47QX6x6yU0v5RG8QjsL5wdwb0Ni/XGWenR070025UPK0a3Jzj4HZKv7RBoN3HTPt/3xsRrCWL8LvUcFxAEmeah7YLT1Mqa6CwKKMzKrJQUuAsNYw4ODbhgvEoQ5H7mq+xW+eEjXYeOle8niVvEUxJNloK5o8Vixm7tw82FbItFTS9CvLXiY3f0dTwA0vLXR60j9+3VmfqDgw8LUNPaO9u7n64QoaaYpDsKFnUvyz2gOt marc@cc-cb63088e-67bcf4b4f8-wgmp8 non-prod-test'
            }
          ]
        }
      }
      computerName: vmName
    }
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      imageReference: {
        offer: 'UbuntuServer'
        publisher: 'Canonical'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption:'FromImage'
        diskSizeGB: 30
        caching:'ReadWrite'
        managedDisk: {
          storageAccountType:'Premium_LRS'
        }
        name: '${vmName}-osDisk'
        osType:'Linux'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary:true
          }
          id: nic.outputs.nicId
        }
      ]
    }
  }
}

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status:'Enabled'
    dailyRecurrence:{
      time: '2100'
    }
    notificationSettings: {
      status:'Disabled'
    }
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: vm.id
    timeZoneId: 'GMT Standard Time'
  }
}

output nicPrivateIp string = nic.outputs.nicPrivateIp
