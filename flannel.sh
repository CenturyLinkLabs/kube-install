#!/bin/bash

yum -y install flannel

echo "# Flanneld configuration options

# etcd url location.  Point this to the server where etcd runs
FLANNEL_ETCD=\"http://master:4001\"

# etcd config key.  This is the configuration key that flannel queries
# For address range assignment
FLANNEL_ETCD_KEY=\"/coreos.com/network\"

# Any additional options that you want to pass
#FLANNEL_OPTIONS=\"--iface=eth0\"" > flanneld

sudo mv flanneld /etc/sysconfig/

sudo systemctl restart flanneld

sudo cp /usr/lib/systemd/system/docker.service docker-bak.service

echo "
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target

[Service]
Type=notify
EnvironmentFile=-/run/flannel/subnet.env
EnvironmentFile=-/etc/sysconfig/docker
EnvironmentFile=-/etc/sysconfig/docker-storage
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/usr/bin/docker -d \
          \$OPTIONS \
          \$DOCKER_STORAGE_OPTIONS \
          \$DOCKER_NETWORK_OPTIONS \
          \$INSECURE_REGISTRY --bip=\${FLANNEL_SUBNET} --mtu=\${FLANNEL_MTU}
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
MountFlags=slave

[Install]
WantedBy=multi-user.target" > docker.service

sudo mv docker.service /usr/lib/systemd/system/
sudo systemctl daemon-reload