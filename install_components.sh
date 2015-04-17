#!/bin/sh

mkdir -p /var/run/kubernetes

echo "[virt7-testing]
name=CentOS CBS - Virt7 Testing
baseurl=http://cbs.centos.org/repos/virt7-testing/x86_64/os/
gpgcheck=0" > virt7-testing.repo && sudo mv virt7-testing.repo /etc/yum.repos.d/

yum -y update  --skip-broken
yum -y erase etcd
yum -y install wget iptables-services
yum -y install http://cbs.centos.org/kojifiles/packages/etcd/0.4.6/7.el7.centos/x86_64/etcd-0.4.6-7.el7.centos.x86_64.rpm
yum -y install http://cbs.centos.org/kojifiles/packages/kubernetes/0.15.0/0.1.gitd02139d.el7/x86_64/kubernetes-0.15.0-0.1.gitd02139d.el7.x86_64.rpm

systemctl disable iptables-services firewalld
systemctl stop iptables-services firewalld

