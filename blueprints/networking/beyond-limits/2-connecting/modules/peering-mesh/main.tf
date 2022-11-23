module "peering" {
  for_each = var.peer_networks
  source   = "../../../../../../modules/net-vpc-peering"

  local_network = var.local_network
  peer_network  = each.key
}

variable "local_network" {
  description = "Resource link of the network to add a peering to."
  type        = string
}

variable "peer_networks" {
  description = "List of resource links of the peer networks."
  type        = set(string)
}
