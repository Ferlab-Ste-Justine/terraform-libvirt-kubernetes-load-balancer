# About

This terraform module provisions an Haproxy load balancer for a kubernetes cluster.

Its is a transport-level load-balancer that doesn't perform tls termination, leaving that concern to the downstream kubernetes cluster (presumably via an ingress).

The load balancer currently expects to load balance to the following services:
- The kubernetes api on the masters (port 6443 on the load balancer, customizable port on the masters)
- The http ingress on the workers (port 80 on the load balancer, customizable port on the workers)
- The https ingress on the workers (port 443 on the load balancer, customization port on the workers)

The load balancer also expects external dns servers that it will use to continuously resolve the kubernetes workers and masters ips.

It will furthermore do a basic connection check on the masters and workers for each load-balanced services and it will temporarily prune away the nodes that don't pass the check for each service.

# Usage

## Input

The module takes the following variables as input:

- **name**: Name of the load balancer vm
- **vcpus**: Number of vcpus to assign to the load balancer. Defaults to 2.
- **memory**: Amount of memory to assign to the bastion in MiB. Defaults to 8192 (8 GiB).
- **volume_id**: Id of the disk volume to attach to the vm
- **libvirt_network**: Parameters to connect to a libvirt network if you opt for that instead of macvtap interfaces. In has the following keys:
  - **ip**: Ip of the vm.
  - **mac**: Mac address of the vm. If none is passed, a random one will be generated.
  - **network_id**: Id (ie, uuid) of the libvirt network to connect to (in which case **network_name** should be an empty string).
  - **network_name**: Name of the libvirt network to connect to (in which case **network_id** should be an empty string).
- **macvtap_interfaces**: List of macvtap interfaces to connect the vm to if you opt for macvtap interfaces instead of a libvirt network. Each entry in the list is a map with the following keys:
  - **interface**: Host network interface that you plan to connect your macvtap interface with.
  - **prefix_length**: Length of the network prefix for the network the interface will be connected to. For a **192.168.1.0/24** for example, this would be **24**.
  - **ip**: Ip associated with the macvtap interface. 
  - **mac**: Mac address associated with the macvtap interface
  - **gateway**: Ip of the network's gateway for the network the interface will be connected to.
  - **dns_servers**: Dns servers for the network the interface will be connected to. If there aren't dns servers setup for the network your vm will connect to, the ip of external dns servers accessible accessible from the network will work as well.
- **cloud_init_volume_pool**: Name of the volume pool that will contain the cloud-init volume of the vm.
- **cloud_init_volume_name**: Name of the cloud-init volume that will be generated by the module for your vm. If left empty, it will default to ``<vm name>-cloud-init.iso``.
- **ssh_admin_user**: Username of the default sudo user in the image. Defaults to **ubuntu**.
- **admin_user_password**: Optional password for the default sudo user of the image. Note that this will not enable ssh password connections, but it will allow you to log into the vm from the host using the **virsh console** command.
- **ssh_admin_public_key**: Public part of the ssh key that will be used to login as the admin on the vm
- **k8_max_workers_count**: Maximum expected possible number of k8 workers. Required by haproxy. Defaults to 100.
- **k8_max_masters_count**: Maximum expected possible number of k8 master. Required by haproxy. Defaults to 7.
- **k8_nameserver_ips**: Ips of the nameservers the load balancer will use to resolve kubernetes masters and workers
- **k8_domain**: Domain for the kubernetes cluster. The **workers** subdomain is expected to resolve to the ips of the workers and the **masters** subdomain is expected to resolve to the ips of the masters.
- **k8_masters_api_timeout**: Amount of time a kubernetes api connection can remain idle before the load balancer times it out. Defaults to **5000ms**.
- **k8_masters_api_port**: Http port of the kubernetes api on the k8 master nodes. Defaults to **6443**.
- **k8_masters_max_api_connections**: Max number of concurrent connections to the kubernetes api the load balancer will allow before it starts refusing further connections. Defaults to **200**.
- **k8_workers_ingress_http_timeout**: Amount of time an ingress http connection can remain idle before the load balancer times it out. Defaults to **5000ms**.
- **k8_workers_ingress_http_port**: Http port of the ingress on the k8 worker nodes. Defaults to **30000**.
- **k8_workers_ingress_max_http_connections**: Max number of concurrent http connections to the ingress the load balancer will allow before it starts refusing further connections. Defaults to **200**.
- **k8_workers_ingress_https_timeout**: Amount of time an ingress https connection can remain idle before the load balancer times it out. Defaults to **5000ms**
- **k8_workers_ingress_https_port**: Https port of the ingress on the k8 worker nodes. Defaults to **30001**.
- **k8_workers_ingress_max_https_connections**: Max number of concurrent https connections to the ingress the load balancer will allow before it starts refusing further connections. Defaults to **200**.
- **chrony**: Optional chrony configuration for when you need a more fine-grained ntp setup on your vm. It is an object with the following fields:
  - **enabled**: If set the false (the default), chrony will not be installed and the vm ntp settings will be left to default.
  - **servers**: List of ntp servers to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server)
  - **pools**: A list of ntp server pools to sync from with each entry containing two properties, **url** and **options** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool)
  - **makestep**: An object containing remedial instructions if the clock of the vm is significantly out of sync at startup. It is an object containing two properties, **threshold** and **limit** (see: https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep)