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

# tfdoc:file:description Orchestration project and VPC.

locals {
  group_iam_orc = {
    "${local.groups.data-engineers}" = [
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
      "roles/cloudbuild.builds.editor",
      "roles/composer.admin",
      "roles/composer.environmentAndStorageObjectAdmin",
      "roles/iap.httpsResourceAccessor",
      "roles/iam.serviceAccountUser",
      "roles/compute.networkUser",
      "roles/storage.objectAdmin",
      "roles/storage.admin",
      "roles/compute.networkUser"
    ]
  }

  iam_orc = {
    "roles/bigquery.dataEditor" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email,
      module.orc-sa-cmp-0.iam_email,
    ]
    "roles/bigquery.jobUser" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email,
      module.orc-sa-cmp-0.iam_email,
    ]
    "roles/composer.worker" = [
      module.orc-sa-cmp-0.iam_email
    ]
    "roles/compute.networkUser" = [
      module.orc-sa-cmp-0.iam_email,
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email,
      "serviceAccount:${module.orc-prj.service_accounts.robots.container-engine}",
      "serviceAccount:${module.lod-prj.service_accounts.robots.dataflow}",
      "serviceAccount:${module.trf-prj.service_accounts.robots.dataflow}",
      "serviceAccount:${module.orc-prj.service_accounts.cloud_services}"
    ]
    "roles/iam.serviceAccountUser" = [
      module.orc-sa-cmp-0.iam_email,
    ]
    "roles/storage.objectAdmin" = [
      module.lod-sa-df-0.iam_email,
      module.orc-sa-cmp-0.iam_email,
      "serviceAccount:${module.orc-prj.service_accounts.robots.composer}",
    ]
    "roles/storage.admin" = [
      module.lod-sa-df-0.iam_email,
      module.trf-sa-df-0.iam_email
    ]
  }

  prefix_orc = "${var.prefix}-orc"
}

module "orc-prj" {
  source          = "../../../modules/project"
  name            = try(var.project_ids["orchestration"], "orc")
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = can(var.project_ids["orchestration"])
  prefix          = can(var.project_ids["orchestration"]) ? var.prefix : null
  # additive IAM bindings avoid disrupting bindings in existing project
  iam          = var.project_create != null ? local.iam_orc : {}
  iam_additive = var.project_create == null ? local.iam_orc : {}
  group_iam    = local.group_iam_orc
  oslogin      = false
  policy_boolean = {
    "constraints/compute.requireOsLogin" = false
  }
  services = concat(
    var.project_services,
    [
      "artifactregistry.googleapis.com",
      "bigquery.googleapis.com",
      "bigqueryreservation.googleapis.com",
      "bigquerystorage.googleapis.com",
      "cloudbuild.googleapis.com",
      "cloudkms.googleapis.com",
      "composer.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
      "containerregistry.googleapis.com",
      "dataflow.googleapis.com",
      "pubsub.googleapis.com",
      "servicenetworking.googleapis.com",
      "storage.googleapis.com",
      "storage-component.googleapis.com"
  ])
  service_encryption_key_ids = {
    composer = [try(local.service_encryption_keys.composer, null)]
    storage  = [try(local.service_encryption_keys.storage, null)]
  }
  shared_vpc_service_config = local._shared_vpc_service_config
}

module "orc-vpc" {
  count      = var.network_config.network_self_link != null ? 0 : 1
  source     = "../../../modules/net-vpc"
  project_id = module.orc-prj.project_id
  name       = "${local.prefix_orc}-vpc"
  subnets = [
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "${local.prefix_orc}-subnet"
      region        = var.location_config.region
      secondary_ip_range = {
        pods     = "10.10.8.0/22"
        services = "10.10.12.0/24"
      }
    }
  ]
}

resource "google_project_iam_binding" "composer_shared_vpc_agent" {
  count   = var.network_config.network_self_link != null ? 1 : 0
  project = local._shared_vpc_project
  role    = "roles/composer.sharedVpcAgent"
  members = [
    "serviceAccount:${module.orc-prj.service_accounts.robots.composer}"
  ]
}

resource "google_project_iam_binding" "gke_host_service_agent_user" {
  count   = var.network_config.network_self_link != null ? 1 : 0
  project = local._shared_vpc_project
  role    = "roles/container.hostServiceAgentUser"
  members = [
    "serviceAccount:${module.orc-prj.service_accounts.robots.container-engine}"
  ]
}

resource "google_project_iam_binding" "composer_network_user_agent" {
  count   = var.network_config.network_self_link != null ? 1 : 0
  project = local._shared_vpc_project
  role    = "roles/compute.networkUser"
  members = [
    module.orc-sa-cmp-0.iam_email,
    module.lod-sa-df-0.iam_email,
    module.trf-sa-df-0.iam_email,
    "serviceAccount:${module.lod-prj.service_accounts.robots.dataflow}",
    "serviceAccount:${module.orc-prj.service_accounts.cloud_services}",
    "serviceAccount:${module.orc-prj.service_accounts.robots.container-engine}",
    "serviceAccount:${module.trf-prj.service_accounts.robots.dataflow}",
  ]
}

module "orc-vpc-firewall" {
  count        = var.network_config.network_self_link != null ? 0 : 1
  source       = "../../../modules/net-vpc-firewall"
  project_id   = module.orc-prj.project_id
  network      = local._networks.orchestration.network_name
  admin_ranges = ["10.10.0.0/24"]
}

module "orc-nat" {
  count          = var.network_config.network_self_link != null ? 0 : 1
  source         = "../../../modules/net-cloudnat"
  project_id     = module.orc-prj.project_id
  region         = var.location_config.region
  name           = "${local.prefix_orc}-default"
  router_network = local._networks.orchestration.network_name
}
