# Copyright 2022 Google LLC. This software is provided as-is,
# without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.
#

provider "google" {
  # impersonate_service_account = "service account"
  # access_token = data.google_service_account_access_token.default.access_token
  # version      = "~> 3.30"
}

provider "google-beta" {
  # access_token = data.google_service_account_access_token.default.access_token
  # version      = "~> 3.30"
}

