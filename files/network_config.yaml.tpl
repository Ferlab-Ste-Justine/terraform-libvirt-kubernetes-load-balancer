version: 2
renderer: networkd
ethernets:
  eth0:
    dhcp4: no
    match:
      name: ${interface_name_match}
    addresses:
      - ${vm_ip}/${subnet_prefix_length}
    gateway4: ${gateway_ip}
%{ if length(dns_servers) > 0 ~}
    nameservers:
      addresses: [${join(",", dns_servers)}]
%{ endif ~}