#!/bin/sh

mkdir -p /var/run/kubernetes

echo "[virt7-testing]
name=CentOS CBS - Virt7 Testing
baseurl=http://cbs.centos.org/repos/virt7-testing/x86_64/os/
gpgcheck=0" > virt7-testing.repo && sudo mv virt7-testing.repo /etc/yum.repos.d/

yum -y update  --skip-broken
yum -y erase etcd
yum -y install wget iptables-services etcd
#yum -y install http://cbs.centos.org/kojifiles/packages/etcd/2.0.9/1.el7/x86_64/etcd-2.0.9-1.el7.x86_64.rpm
yum -y install http://cbs.centos.org/kojifiles/packages/kubernetes/0.16.2/2.el7/x86_64/kubernetes-0.16.2-2.el7.x86_64.rpm

systemctl disable iptables-services firewalld
systemctl stop iptables-services firewalld

