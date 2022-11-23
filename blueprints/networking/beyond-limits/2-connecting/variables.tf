variable "network-config" {
  description = "The Network config; this is the output of stage 1 extended by the object containing router information"
  type = map(
    object({
      network_id = string
      spokes = map(
        object({
          network_id = string
          regions = map(
            object({
              asn                       = string
              peer-asn                  = string
              bgp-cidr-range            = string
              bgp_announced_cidr_ranges = optional(map(string), {})
            })
          )
        })
      )
    })
  )
}

variable "spoke-cidr-announcements" {
  description = "The IP ranges that will be announced to the different spokes from the connectivity project"
  type        = map(string)
  default = {
    "10.0.0.0/8"     = "RFC 1918 class A",
    "172.16.0.0/12"  = "RFC 1918 class B",
    "192.168.0.0/16" = "RFC 1918 class C"
  }
}

variable "advertise-spoke-subnets" {
  description = "Wether to advertise spoke subnet cidrs over VPN directly. Take care about limits if you enable this"
  type        = bool
  default     = false
}
