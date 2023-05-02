variable "name" {
  description = "Name to give to the vm."
  type        = string
}

variable "vcpus" {
  description = "Number of vcpus to assign to the vm"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Amount of memory in MiB"
  type        = number
  default     = 8192
}

variable "volume_id" {
  description = "Id of the disk volume to attach to the vm"
  type        = string
}

variable "libvirt_network" {
  description = "Parameters of the libvirt network connection if a libvirt network is used. Has the following parameters: network_id, network_name, ip, mac"
  type = object({
    network_name = string
    network_id = string
    ip = string
    mac = string
  })
  default = {
    network_name = ""
    network_id = ""
    ip = ""
    mac = ""
  }
}

variable "macvtap_interfaces" {
  description = "List of macvtap interfaces. Mutually exclusive with the network_id, ip and mac fields. Each entry has the following keys: interface, prefix_length, ip, mac, gateway and dns_servers"
  type        = list(object({
    interface = string,
    prefix_length = number,
    ip = string,
    mac = string,
    gateway = string,
    dns_servers = list(string),
  }))
  default = []
}

variable "cloud_init_volume_pool" {
  description = "Name of the volume pool that will contain the cloud init volume"
  type        = string
}

variable "cloud_init_volume_name" {
  description = "Name of the cloud init volume"
  type        = string
  default = ""
}

variable "ssh_admin_user" { 
  description = "Pre-existing ssh admin user of the image"
  type        = string
  default     = "ubuntu"
}

variable "admin_user_password" { 
  description = "Optional password for admin user"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_admin_public_key" {
  description = "Public ssh part of the ssh key the admin will be able to login as"
  type        = string
}

variable "ssh_host_key_rsa" {
  type = object({
    public = string
    private = string
  })
  default = {
    public = ""
    private = ""
  }
}

variable "ssh_host_key_ecdsa" {
  type = object({
    public = string
    private = string
  })
  default = {
    public = ""
    private = ""
  }
}

variable "k8_max_workers_count" {
  description = "Maximum expected number of k8 workers"
  type = number
  default = 100
}

variable "k8_max_masters_count" {
  description = "Maximum expected number of k8 masters"
  type = number
  default = 7
}

variable "k8_nameserver_ips" {
  description = "Ips of the nameservers the load balance will use to resolve k8 masters and workers"
  type = list(string)
}

variable "k8_domain" {
  description = "Domain that will resolve to the k8 masters and workers on the dns servers"
  type = string
}

variable "k8_masters_api_timeout" {
  description = "Amount of time an api connection can remain idle before it times out"
  type = string
  default = "5000ms"
}

variable "k8_masters_api_port" {
  description = "Http port of the api on the k8 masters"
  type = number
  default = 6443
}

variable "k8_masters_max_api_connections" {
  description = "Max number of concurrent api connections on the masters"
  type = number
  default = 200
}

variable "k8_workers_ingress_http_timeout" {
  description = "Amount of time an ingress http connection can remain idle before it times out"
  type = string
  default = "5000ms"
}

variable "k8_workers_ingress_http_port" {
  description = "Http port of the ingress on the k8 workers"
  type = number
  default = 30000
}

variable "k8_workers_ingress_max_http_connections" {
  description = "Max number of concurrent http connections the load balancer will allow on the workers"
  type = number
  default = 200
}

variable "k8_workers_ingress_https_timeout" {
  description = "Amount of time an ingress https connection can remain idle before it times out"
  type = string
  default = "5000ms"
}

variable "k8_workers_ingress_https_port" {
  description = "Https port of the ingress on the k8 workers"
  type = number
  default = 30001
}

variable "k8_workers_ingress_max_https_connections" {
  description = "Max number of concurrent https connections the load balancer will allow on the workers"
  type = number
  default = 200
}

variable docker_registry_auth {
  description = "Docker registry authentication settings"
  type        = object({
    enabled  = bool,
    url      = string,
    username = string,
    password = string
  })
  default = {
    enabled  = false
    url      = "https://index.docker.io/v1/"
    username = ""
    password = ""
  }
}

variable "tunnel" {
  description = "Setting for restricting the bastion access via an ssh tunnel only"
  type = object({
    enabled = bool
    ssh = object({
      user = string
      authorized_key = string
    })
  })
  default = {
    enabled = false
    ssh = {
      user = ""
      authorized_key = ""
    }
  }
}

variable "chrony" {
  description = "Chrony configuration for ntp. If enabled, chrony is installed and configured, else the default image ntp settings are kept"
  type        = object({
    enabled = bool,
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server
    servers = list(object({
      url = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool
    pools = list(object({
      url = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep
    makestep = object({
      threshold = number,
      limit = number
    })
  })
  default = {
    enabled = false
    servers = []
    pools = []
    makestep = {
      threshold = 0,
      limit = 0
    }
  }
}