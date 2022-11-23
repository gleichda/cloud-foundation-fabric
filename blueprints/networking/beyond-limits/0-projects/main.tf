# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  services = [
    "compute.googleapis.com"
  ]
  projects = {
    for i in range(var.connectivity-projects-count) :
    "con${i}" =>
    [
      for j in range(var.spokes-per-connectivity) :
      "con${i}-spoke${j}"
    ]
  }
}

# Connectivity Projects
module "connectivity" {
  for_each        = local.projects
  source          = "../../../../modules/project"
  billing_account = var.billing_account
  name            = "${each.key}-${random_id.connectivity-suffix[each.key].hex}"
  parent          = var.parent
  prefix          = var.prefix
  services        = local.services
}

# Shared VPC Host Projects
# TODO: Shared VPC Config
module "spoke" {
  for_each        = toset(flatten(values(local.projects)))
  source          = "../../../../modules/project"
  billing_account = var.billing_account
  name            = "${each.key}-${random_id.spoke-suffix[each.key].hex}"
  parent          = var.parent
  prefix          = var.prefix
  services        = local.services
}

#TODO Random per project
resource "random_id" "spoke-suffix" {
  for_each    = toset(flatten(values(local.projects)))
  byte_length = 2
}

resource "random_id" "connectivity-suffix" {
  for_each    = local.projects
  byte_length = 2
}
