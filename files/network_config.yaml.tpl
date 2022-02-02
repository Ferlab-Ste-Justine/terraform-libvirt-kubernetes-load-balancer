version: 2
renderer: networkd
ethernets:
%{ for idx, val in macvtap_interfaces ~}
  eth${idx}:
    dhcp4: no
    match:
      macaddress: ${val.mac}
    addresses:
      - ${val.ip}/${val.prefix_length}
    gateway4: ${val.gateway}
%{ if length(val.dns_servers) > 0 ~}
    nameservers:
      addresses: [${join(",", val.dns_servers)}]
%{ endif ~}
%{ endfor ~}