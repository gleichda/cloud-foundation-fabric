# Copyright 2022 Google LLC. This software is provided as-is,
# without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.


locals {
  vpn-list-helper = merge([
    for con-proj, config in var.network-config :
    config.spokes
  ]...)

  vpn-list-helper-region = {
    for spoke, config in local.vpn-list-helper :
    spoke => merge(config,
      {
        for con-proj, con-config in var.network-config :
        "connectivity-project" => con-proj
        if contains(keys(con-config.spokes), spoke)
      }
    )
  }
  vpn-list = merge([
    for project, config in local.vpn-list-helper-region : {
      for region, data in config.regions :
      "${project}-${region}" => merge(data, { "connectivity-project" = config.connectivity-project, "spoke-project" = project, "region" = region })
    }
  ]...)
  spoke-gateways-helper = toset([for vpn, config in local.vpn-list :
    {
      "connectivity-project" = config.connectivity-project
      "region"               = config.region
      "network_id"           = var.network-config[config.connectivity-project].network_id
    }
  ])

  spoke-gateways = { for gw in local.spoke-gateways-helper :
    "${gw.connectivity-project}-${gw.region}" => gw
  }
}

# VPN Gateways need to be created separately in order to avid cyclic dependencies
# see also https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/modules/net-vpn-ha/README.md
resource "google_compute_ha_vpn_gateway" "ha-gateway-spoke" {
  for_each = local.vpn-list
  project  = each.value.spoke-project
  region   = each.value.region
  name     = "${each.value.region}-spoke-con"
  network  = var.network-config[each.value.connectivity-project].spokes[each.value.spoke-project].network_id
}

resource "google_compute_ha_vpn_gateway" "ha-gateway-con" {
  for_each = local.spoke-gateways
  project  = each.value.connectivity-project
  region   = each.value.region
  name     = "${each.value.region}-spoke-con"
  network  = each.value.network_id
}


module "vpn-con-spoke" {
  for_each           = local.vpn-list
  source             = "../../../../modules/net-vpn-ha"
  project_id         = each.value.connectivity-project
  region             = each.value.region
  network            = var.network-config[each.value.connectivity-project].network_id
  name               = each.key
  vpn_gateway        = google_compute_ha_vpn_gateway.ha-gateway-con["${each.value.connectivity-project}-${each.value.region}"].id
  peer_gcp_gateway   = google_compute_ha_vpn_gateway.ha-gateway-spoke["${each.value.spoke-project}-${each.value.region}"].id
  vpn_gateway_create = false
  router_asn         = each.value.peer-asn

  router_advertise_config = {
    mode : "CUSTOM",
    groups : [],
    ip_ranges : var.spoke-cidr-announcements
  }


  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = cidrhost(each.value.bgp-cidr-range, 1) # First IP except Gateway
        asn     = each.value.asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(each.value.bgp-cidr-range, 2)}/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret         = random_password.vpn-psk[each.key].result
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = cidrhost(each.value.bgp-cidr-range, 5) # First IP of second subnet
        asn     = each.value.asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(each.value.bgp-cidr-range, 6)}/30" # Always the IP in the CIDR will be used as router IP
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = random_password.vpn-psk[each.key].result
      vpn_gateway_interface           = 1
    }
  }
}


module "vpn-spoke-con" {
  for_each           = local.vpn-list
  source             = "../../../../modules/net-vpn-ha"
  project_id         = each.value.spoke-project
  region             = each.value.region
  network            = var.network-config[each.value.connectivity-project].spokes[each.value.spoke-project].network_id
  name               = each.key
  peer_gcp_gateway   = google_compute_ha_vpn_gateway.ha-gateway-con["${each.value.connectivity-project}-${each.value.region}"].id
  vpn_gateway        = google_compute_ha_vpn_gateway.ha-gateway-spoke["${each.value.spoke-project}-${each.value.region}"].id
  vpn_gateway_create = false
  router_asn         = each.value.asn

  router_advertise_config = {
    groups    = var.advertise-spoke-subnets ? ["ALL_SUBNETS"] : []
    ip_ranges = each.value.bgp_announced_cidr_ranges
    mode      = "CUSTOM"
  }

  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = cidrhost(each.value.bgp-cidr-range, 2) # Second IP except Gateway
        asn     = each.value.peer-asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(each.value.bgp-cidr-range, 1)}/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = random_password.vpn-psk[each.key].result
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = cidrhost(each.value.bgp-cidr-range, 6) # Second IP of second subnet
        asn     = each.value.peer-asn
      }
      bgp_peer_options                = null
      bgp_session_range               = "${cidrhost(each.value.bgp-cidr-range, 5)}/30" # cidrsubnet(each.value.bgp-cidr-range, 1, 1)
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = random_password.vpn-psk[each.key].result
      vpn_gateway_interface           = 1
    }
  }
}

resource "random_password" "vpn-psk" {
  for_each = local.vpn-list
  length   = 32
}
