#cloud-config
%{ if admin_user_password != "" ~}
ssh_pwauth: false
chpasswd:
  expire: False
  users:
    - name: ${ssh_admin_user}
      password: "${admin_user_password}"
      type: text
%{ endif ~}
preserve_hostname: false
hostname: ${node_name}
%{ if ssh_host_key_rsa.public != "" || ssh_host_key_ecdsa.public != "" ~}
ssh_keys:
%{ if ssh_host_key_rsa.public != "" ~}
  rsa_public: ${ssh_host_key_rsa.public}
  rsa_private: |
    ${indent(4, ssh_host_key_rsa.private)}
%{ endif ~}
%{ if ssh_host_key_ecdsa.public != "" ~}
  ecdsa_public: ${ssh_host_key_ecdsa.public}
  ecdsa_private: |
    ${indent(4, ssh_host_key_ecdsa.private)}
%{ endif ~}
%{ endif ~}
users:
  - default
%{ if tunnel.enabled ~}
  - name: ${tunnel.ssh.user}
    lock_passwd: true
    no_user_group: true
    shell: "/bin/false"
    ssh_authorized_keys:
      - "${tunnel.ssh.authorized_key}"
%{ endif ~}
  - name: node-exporter
    system: True
    lock_passwd: True
  - name: ${ssh_admin_user}
    ssh_authorized_keys:
      - "${ssh_admin_public_key}"
write_files:
%{ if docker_registry_auth.enabled ~}
  - path: /root/.docker/config.json
    owner: root:root
    permissions: "0600"
    content: |
      {
        "auths": {
          "${docker_registry_auth.url}": {
            "auth": "${base64encode("${docker_registry_auth.username}:${docker_registry_auth.password}")}"
          }
        }
      }
%{ endif ~}
  #k8 api load balancer haproxy configuration
  - path: /opt/haproxy/haproxy.cfg
    owner: root:root
    permissions: "0444"
    content: |
      ${indent(6, haproxy_config)}
  #Chrony config
%{ if chrony.enabled ~}
  - path: /opt/chrony.conf
    owner: root:root
    permissions: "0444"
    content: |
%{ for server in chrony.servers ~}
      server ${join(" ", concat([server.url], server.options))}
%{ endfor ~}
%{ for pool in chrony.pools ~}
      pool ${join(" ", concat([pool.url], pool.options))}
%{ endfor ~}
      driftfile /var/lib/chrony/drift
      makestep ${chrony.makestep.threshold} ${chrony.makestep.limit}
      rtcsync
%{ endif ~}
  #Prometheus node exporter systemd configuration
  - path: /etc/systemd/system/node-exporter.service
    owner: root:root
    permissions: "0444"
    content: |
      [Unit]
      Description="Prometheus Node Exporter"
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=node-exporter
      Group=node-exporter
      Type=simple
      Restart=always
      RestartSec=1
      ExecStart=/usr/local/bin/node_exporter

      [Install]
      WantedBy=multi-user.target
%{ if tunnel.enabled ~}
  - path: /opt/tunnel_ssh_entry
    owner: root:root
    permissions: "0444"
    content: |
      Match User ${tunnel.ssh.user}
        AllowAgentForwarding no
        PermitTTY no
        X11Forwarding no
        PermitOpen 127.0.0.1:80 127.0.0.1:443 127.0.0.1:6443
%{ endif ~}
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
%{ if chrony.enabled ~}
  - chrony
%{ endif ~}
runcmd:
  #Finalize Chrony Setup
%{ if chrony.enabled ~}
  - cp /opt/chrony.conf /etc/chrony/chrony.conf
  - systemctl restart chrony.service 
%{ endif ~}
  #Install k8 api load balancer as a background docker container
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io
  - systemctl enable docker
  - docker run -d --restart=always --name=k8_masters_load_balancer --network=host -v /opt/haproxy:/usr/local/etc/haproxy:ro --log-driver=journald haproxy:2.2.14
  #Install prometheus node exporter as a binary managed as a systemd service
  - wget -O /opt/node_exporter.tar.gz https://github.com/prometheus/node_exporter/releases/download/v1.3.0/node_exporter-1.3.0.linux-amd64.tar.gz
  - mkdir -p /opt/node_exporter
  - tar zxvf /opt/node_exporter.tar.gz -C /opt/node_exporter
  - cp /opt/node_exporter/node_exporter-1.3.0.linux-amd64/node_exporter /usr/local/bin/node_exporter
  - chown node-exporter:node-exporter /usr/local/bin/node_exporter
  - rm -r /opt/node_exporter && rm /opt/node_exporter.tar.gz
  - systemctl enable node-exporter
  - systemctl start node-exporter
%{ if tunnel.enabled ~}
  - cat /opt/tunnel_ssh_entry >> /etc/ssh/sshd_config
  - rm /opt/tunnel_ssh_entry
%{ endif ~}