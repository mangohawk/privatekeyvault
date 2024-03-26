param userAssignedIdentities string

module delay './delay.bicep' = {
  name: 'delay-1'
   params: {
    name: userAssignedIdentities
   }
}

module delay2 './delay.bicep' = {
  name: 'delay-2'
   params: {
    name: userAssignedIdentities
   }
  dependsOn: [
    delay
  ]
}

module delay3 './delay.bicep' = {
  name: 'delay-3'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay2
  ]
}

module delay4 './delay.bicep' = {
  name: 'delay-4'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay3
  ]
}

module delay5 './delay.bicep' = {
  name: 'delay-5'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay4
  ]
}

module delay6 './delay.bicep' = {
  name: 'delay-6'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay5
  ]
}

module delay7 './delay.bicep' = {
  name: 'delay-7'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay6
  ]
}

module delay8 './delay.bicep' = {
  name: 'delay-8'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay7
  ]
}

module delay9 './delay.bicep' = {
  name: 'delay-9'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay8
  ]
}

module delay10 './delay.bicep' = {
  name: 'delay-10'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay9
  ]
}

module delay11 './delay.bicep' = {
  name: 'delay-11'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay10
  ]
}

module delay12 './delay.bicep' = {
  name: 'delay-12'
   params: {
    name: userAssignedIdentities
   }
   dependsOn: [
    delay11
  ]
}
