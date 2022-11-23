# Copyright 2022 Google LLC. This software is provided as-is,
# without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.
#

locals {
  project-vpcs = merge(
    # TODO [0]?
    merge([
      for connectivity, spokes in local.stage0-output : {
        for spoke, subnets in spokes.spokes :
        spoke => merge(subnets,
          { network_name = join("", compact(regex(local.vpc-regex, spoke))) }
        )
    }]...),
    {
      for connectivity, spokes in local.stage0-output :
      connectivity => {
        subnets      = [],
        network_name = join("", compact(regex(local.vpc-regex, connectivity)))
      }
    }
  )
  vpc-regex = "(con[0-9]+)(-spoke[0-9]+)?"

  stage0-output = data.terraform_remote_state.vpcs.outputs.stage1-input
}


module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.2.0"

  for_each = local.project-vpcs

  project_id                             = each.key
  network_name                           = each.value.network_name
  delete_default_internet_gateway_routes = true

  subnets = each.value.subnets

  routes = [
    {
      name              = "route-to-nat-default"
      tags              = "nat"
      destination_range = "0.0.0.0/0"
      next_hop_internet = "true"
      priority          = 1000
    }
  ]
}
