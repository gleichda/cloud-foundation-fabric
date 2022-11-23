# Copyright 2022 Google LLC. This software is provided as-is,
# without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.
#

locals {
  peered-projects = [
    for id, project in var.network-config :
    id
    #Ignore spokes with this regex
    if length(regexall(local.spoke-regex, id)) == 0
  ]

  peering-mesh = {
    for index, project-a in local.peered-projects :
    var.network-config["${project-a}"].network_id => [
      for i in range(index + 1, length(local.peered-projects)) :
      var.network-config["${element(local.peered-projects, i)}"].network_id
    ]
  }
  spoke-regex   = "(con[0-9]+)(-spoke[0-9]+)"
}

module "vpc-mesh" {
  source   = "./modules/peering-mesh"
  for_each = local.peering-mesh

  local_network = each.key
  peer_networks = each.value
}
