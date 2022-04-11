/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "cloudsql_psa_range" {
  description = "Range used for the Private Service Access."
  type        = string
  default     = "10.60.0.0/16"
}

variable "prefix" {
  description = "Unique prefix used for resource names. Not used for project if 'project_create' is null."
  type        = string
}

variable "project_create" {
  description = "Provide values if project creation is needed, uses existing project if null. Parent is in 'folders/nnn' or 'organizations/nnn' format."
  type = object({
    billing_account_id = string
    parent             = string
  })
  default = null
}

variable "project_id" {
  description = "Project id, references existing project if `project_create` is null."
  type        = string
}

variable "regions" {
  description = "Map of instance_name => location where instances will be deployed."
  type        = map(string)
  validation {
    condition     = contains(keys(var.regions), "primary")
    error_message = "Regions map must contain `primary` as a key."
  }
}

variable "tier" {
  description = "The machine type to use for the instances. See See https://cloud.google.com/sql/docs/postgres/create-instance#machine-types."
  type        = string
  default     = "db-g1-small"
}