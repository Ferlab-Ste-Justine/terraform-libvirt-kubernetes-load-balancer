locals {
  cloud_init_volume_name = var.cloud_init_volume_name == "" ? "${var.name}-cloud-init.iso" : var.cloud_init_volume_name
  network_config = templatefile(
    "${path.module}/files/network_config.yaml.tpl", 
    {
      interface_name_match = var.macvtap_vm_interface_name_match
      subnet_prefix_length = var.macvtap_subnet_prefix_length
      vm_ip = var.ip
      gateway_ip = var.macvtap_gateway_ip
      dns_servers = var.macvtap_dns_servers
    }
  )
}

data "template_cloudinit_config" "user_data" {
  gzip = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/files/user_data.yaml.tpl", 
      {
        node_name = var.name
        ssh_admin_public_key = var.ssh_admin_public_key
        ssh_admin_user = var.ssh_admin_user
        admin_user_password = var.admin_user_password
        haproxy_config = templatefile(
          "${path.module}/files/lb-haproxy.cfg",
          {
            k8_nameserver_ips = var.k8_nameserver_ips
            k8_domain = var.k8_domain
            k8_ingress_http_timeout = var.k8_workers_ingress_http_timeout
            k8_ingress_http_port = var.k8_workers_ingress_http_port
            k8_ingress_max_http_connections = var.k8_workers_ingress_max_http_connections
            k8_ingress_https_timeout = var.k8_workers_ingress_https_timeout
            k8_ingress_https_port = var.k8_workers_ingress_https_port
            k8_ingress_max_https_connections = var.k8_workers_ingress_max_https_connections
            k8_api_timeout = var.k8_masters_api_timeout
            k8_api_port = var.k8_masters_api_port
            k8_max_api_connections = var.k8_masters_max_api_connections
            k8_max_masters_count = var.k8_max_masters_count
            k8_max_workers_count = var.k8_max_workers_count
          }
        )
      }
    )
  }
}

resource "libvirt_cloudinit_disk" "k8_node" {
  name           = local.cloud_init_volume_name
  user_data      = data.template_cloudinit_config.user_data.rendered
  network_config = var.macvtap_interface != "" ? local.network_config : null
  pool           = var.cloud_init_volume_pool
}

resource "libvirt_domain" "k8_node" {
  name = var.name

  cpu {
    mode = "host-passthrough"
  }

  vcpu = var.vcpus
  memory = var.memory

  disk {
    volume_id = var.volume_id
  }

  network_interface {
    network_id = var.network_id != "" ? var.network_id : null
    macvtap = var.macvtap_interface != "" ? var.macvtap_interface : null
    addresses = var.network_id != "" ? [var.ip] : null
    mac = var.mac != "" ? var.mac : null
    hostname = var.network_id != "" ? var.name : null
  }

  autostart = true

  cloudinit = libvirt_cloudinit_disk.k8_node.id

  //https://github.com/dmacvicar/terraform-provider-libvirt/blob/main/examples/v0.13/ubuntu/ubuntu-example.tf#L61
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }
}