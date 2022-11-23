# Copyright 2022 Google LLC. This software is provided as-is,
# without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.
#

output "project-vpcs" {
  value = local.project-vpcs
}

output "stage2-input" {
  value = {
    for con-project, con-config in local.stage0-output :
    con-project => {
      spokes = { for spoke, data in con-config.spokes :
        spoke => merge(data, { network_id = module.vpc["${spoke}"].network_id, regions = {} })
      }
      network_id = module.vpc["${con-project}"].network_id
    }
  }
}
