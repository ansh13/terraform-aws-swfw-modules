### General
region      = "eu-west-1"  # TODO: update here
name_prefix = "example-"   # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

### VPC - SECURITY VPC ONLY
vpcs = {
  security_vpc = {
    name = "security-vpc"
    cidr = "10.100.0.0/16"
    nacls = {
      trusted_path_monitoring = {
        name = "trusted-path-monitoring"
        rules = {
          block_outbound_icmp_1 = {
            rule_number = 110
            egress      = true
            protocol    = "icmp"
            rule_action = "deny"
            cidr_block  = "10.100.1.0/24"
            from_port   = null
            to_port     = null
          }
          block_outbound_icmp_2 = {
            rule_number = 120
            egress      = true
            protocol    = "icmp"
            rule_action = "deny"
            cidr_block  = "10.100.65.0/24"
            from_port   = null
            to_port     = null
          }
          allow_other_outbound = {
            rule_number = 200
            egress      = true
            protocol    = "-1"
            rule_action = "allow"
            cidr_block  = "0.0.0.0/0"
            from_port   = null
            to_port     = null
          }
          allow_inbound = {
            rule_number = 300
            egress      = false
            protocol    = "-1"
            rule_action = "allow"
            cidr_block  = "0.0.0.0/0"
            from_port   = null
            to_port     = null
          }
        }
      }
    }
    security_groups = {
      vmseries_private = {
        name = "vmseries_private"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          geneve = {
            description = "Permit GENEVE to GWLB subnets"
            type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
            cidr_blocks = [
              "10.100.5.0/24", "10.100.69.0/24"
            ]
          }
          health_probe = {
            description = "Permit Port 80 Health Probe to GWLB subnets"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = [
              "10.100.5.0/24", "10.100.69.0/24"
            ]
          }
        }
      }
      vmseries_mgmt = {
        name = "vmseries_mgmt"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          panorama_ssh = {
            description = "Permit Panorama SSH (Optional)"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["10.0.0.0/8"]
          }
        }
      }
      vmseries_public = {
        name = "vmseries_public"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      "10.100.0.0/24"  = { az = "eu-west-1a", subnet_group = "mgmt" }
      "10.100.64.0/24" = { az = "eu-west-1b", subnet_group = "mgmt" }
      "10.100.1.0/24"  = { az = "eu-west-1a", subnet_group = "private", nacl = "trusted_path_monitoring" }
      "10.100.65.0/24" = { az = "eu-west-1b", subnet_group = "private", nacl = "trusted_path_monitoring" }
      "10.100.2.0/24"  = { az = "eu-west-1a", subnet_group = "public" }
      "10.100.66.0/24" = { az = "eu-west-1b", subnet_group = "public" }
      "10.100.3.0/24"  = { az = "eu-west-1a", subnet_group = "tgw_attach" }
      "10.100.67.0/24" = { az = "eu-west-1b", subnet_group = "tgw_attach" }
      "10.100.4.0/24"  = { az = "eu-west-1a", subnet_group = "gwlbe_outbound" }
      "10.100.68.0/24" = { az = "eu-west-1b", subnet_group = "gwlbe_outbound" }
      "10.100.5.0/24"  = { az = "eu-west-1a", subnet_group = "gwlb" }
      "10.100.69.0/24" = { az = "eu-west-1b", subnet_group = "gwlb" }
    }
    routes = {
      mgmt_default = {
        vpc           = "security_vpc"
        subnet_group  = "mgmt"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      public_default = {
        vpc           = "security_vpc"
        subnet_group  = "public"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      tgw_default = {
        vpc           = "security_vpc"
        subnet_group  = "tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_gwlb_endpoint"
        next_hop_type = "gwlbe_endpoint"
      }
      tgw_rfc1918 = {
        vpc           = "security_vpc"
        subnet_group  = "tgw_attach"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security_gwlb_endpoint"
        next_hop_type = "gwlbe_endpoint"
      }
      gwlbe_outbound_rfc1918 = {
        vpc           = "security_vpc"
        subnet_group  = "gwlbe_outbound"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
    }
  }
}

### GATEWAY LOADBALANCER
gwlbs = {
  security_gwlb = {
    name         = "security-gwlb"
    vpc          = "security_vpc"
    subnet_group = "gwlb"
  }
}

gwlb_endpoints = {
  security_gwlb_endpoint = {
    name            = "security-gwlb-endpoint"
    gwlb            = "security_gwlb"
    vpc             = "security_vpc"
    subnet_group    = "gwlbe_outbound"
    act_as_next_hop = false
  }
}

### AIRS FW - 2 FIREWALLS ONLY (SCM Bootstrap)
vmseries = {
  vmseries = {
    instances = {
      "01" = { az = "eu-west-1a" }
      "02" = { az = "eu-west-1b" }
    }

    # SCM Bootstrap Configuration for AIRS FW (PAN-OS 11.0 or higher)
    bootstrap_options = {
      mgmt-interface-swap                   = "enable"
      panorama-server                       = "cloud"                                                                          # SCM cloud management
      dgname                                = "airs-folder"                                                                    # TODO: update here with your SCM folder name
      dhcp-send-hostname                    = "yes"
      dhcp-send-client-id                   = "yes"
      dhcp-accept-server-hostname           = "yes"
      dhcp-accept-server-domain             = "yes"
      plugin-op-commands                    = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable,advance-routing:enable" # TODO: update here
      vm-series-auto-registration-pin-id    = ""                                                                               # TODO: update here
      vm-series-auto-registration-pin-value = ""                                                                               # TODO: update here
      authcodes                             = ""                                                                               # TODO: update here
    }

    panos_version = "11.2.4-h1" # TODO: update here (AIRS requires PAN-OS 11.2.4-h1 or higher)

    airs_deployment = true # AIRS firewall deployment

    vpc = "security_vpc"

    gwlb = "security_gwlb"

    interfaces = {
      private = {
        device_index      = 0
        security_group    = "vmseries_private"
        subnet_group      = "private"
        create_public_ip  = false
        source_dest_check = false
      }
      mgmt = {
        device_index      = 1
        security_group    = "vmseries_mgmt"
        subnet_group      = "mgmt"
        create_public_ip  = true
        source_dest_check = true
      }
      public = {
        device_index      = 2
        security_group    = "vmseries_public"
        subnet_group      = "public"
        create_public_ip  = true
        source_dest_check = false
      }
    }

    subinterfaces = {
      outbound = {
        only_1_outbound = {
          gwlb_endpoint = "security_gwlb_endpoint"
          subinterface  = "ethernet1/1.20"
        }
      }
    }

    system_services = {
      dns_primary = "4.2.2.2"      # TODO: update here
      ntp_primary = "pool.ntp.org" # TODO: update here
    }

    application_lb = null

    network_lb = null
  }
}

### OPTIONAL: Uncomment if you want Transit Gateway without spoke VPC attachments
# tgws = {
#   tgw = {
#     name = "tgw"
#     asn  = "64512"
#     route_tables = {
#       "from_security_vpc" = {
#         create = true
#         name   = "from_security"
#       }
#     }
#   }
# }
#
# tgw_attachments = {
#   security = {
#     tgw_key                 = "tgw"
#     security_vpc_attachment = true
#     name                    = "vmseries"
#     vpc                     = "security_vpc"
#     subnet_group            = "tgw_attach"
#     route_table             = "from_security_vpc"
#     propagate_routes_to     = []
#   }
# }
