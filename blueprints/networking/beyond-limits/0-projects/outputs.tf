# output "all-projects" {
#   value = local.projects
# }

# output "all-project-ids" {
#   value = concat([module.fake-onprem.google_project.project[0].id], module.connectivity[*].google_project.project[0].id, module.spoke[*].google_project.project[0].id)
# }

output "created-projects" {
  value = {
    for conn-proj, spokes in local.projects :
    module.connectivity["${conn-proj}"].project_id => [
      for spoke in spokes :
      module.spoke["${spoke}"].project_id
    ]
  }
}

output "stage1-input" {
  value = {
    for conn-proj, spokes in local.projects :
    module.connectivity["${conn-proj}"].project_id => {
      spokes = {
        for spoke in spokes :
        module.spoke["${spoke}"].project_id => {
          "subnets" : []
        }
      }
    }
  }
}
