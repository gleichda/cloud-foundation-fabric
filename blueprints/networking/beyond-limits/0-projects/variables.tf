variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.parent == null || can(regex("(organizations|folders)/[0-9]+", var.parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "prefix" {
  description = "Prefix used to generate project id and name."
  type        = string
  default     = null
}

# TODO: Multiple Environments
variable "connectivity-projects-count" {
description = "Number of connectivity projects"
  type = number
}

variable "spokes-per-connectivity" {
description = "Number of spoke projects per connectivity project"
  type = number
}
