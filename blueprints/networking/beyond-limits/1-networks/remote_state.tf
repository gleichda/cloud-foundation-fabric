# Copyright 2022 Google LLC. This software is provided as-is,
# without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.
#



data "terraform_remote_state" "vpcs" {
  backend = "local"

  config = {
    path = "../0-projects/terraform.tfstate"
  }
}

