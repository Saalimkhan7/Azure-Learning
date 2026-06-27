// ============================================================
// Step 1 — VNet + Subnets + NSGs
// AZ-104 Lab | az104-lab resource group
// ============================================================

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('VNet address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Web subnet prefix')
param webSubnetPrefix string = '10.0.1.0/24'

@description('App subnet prefix')
param appSubnetPrefix string = '10.0.2.0/24'

// ── NSG: Web tier ────────────────────────────────────────────
// Allows HTTP + HTTPS from internet, blocks everything else inbound
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-web'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          description: 'Allow HTTP from internet'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          description: 'Allow HTTPS from internet'
        }
      }
      {
        name: 'Allow-RDP-Admin'
        properties: {
          priority: 200
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          description: 'RDP for lab access — restrict to your IP in production'
        }
      }
    ]
  }
}

// ── NSG: App tier ────────────────────────────────────────────
// Only allows traffic from the web subnet (10.0.1.0/24) on port 8080
// This demonstrates subnet-to-subnet NSG control — key AZ-104 concept
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-app'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-From-WebSubnet'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: webSubnetPrefix  // only web subnet
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8080'
          description: 'Allow app traffic from web subnet only'
        }
      }
      {
        name: 'Deny-All-Other-Inbound'
        properties: {
          priority: 4000
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Explicit deny — blocks internet reaching app tier'
        }
      }
    ]
  }
}

// ── Virtual Network ──────────────────────────────────────────
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-main'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ vnetAddressPrefix ]
    }
    subnets: [
      {
        name: 'subnet-web'
        properties: {
          addressPrefix: webSubnetPrefix
          networkSecurityGroup: { id: nsgWeb.id }  // NSG attached at subnet level
        }
      }
      {
        name: 'subnet-app'
        properties: {
          addressPrefix: appSubnetPrefix
          networkSecurityGroup: { id: nsgApp.id }
        }
      }
    ]
  }
}

// ── Outputs (used by later steps) ───────────────────────────
output vnetId string = vnet.id
output webSubnetId string = vnet.properties.subnets[0].id
output appSubnetId string = vnet.properties.subnets[1].id
output nsgWebId string = nsgWeb.id
output nsgAppId string = nsgApp.id
