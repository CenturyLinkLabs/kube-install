#!/bin/bash

set -x
set -e

for i in "$@"
do
echo $i
case `echo $i | tr '[:upper:]' '[:lower:]'` in
    -master-ip=*)
    master_ip="${i#*=}";;
    -minion-ip=*)
    minion_ip="${i#*=}";;
    -uname=*)
    uname="${i#*=}";;
esac
done

echo "[virt7-testing]
name=CentOS CBS - Virt7 Testing
baseurl=http://cbs.centos.org/repos/virt7-testing/x86_64/os/
gpgcheck=0" > virt7-testing.repo && sudo mv virt7-testing.repo /etc/yum.repos.d/

yum -y install --enablerepo=virt7-testing kubernetes
yum -y install firewalld wget kubernetes

echo -e "\n$master_ip master\n$minion_ip  minion1" >> /etc/hosts

sed -i "s#KUBE_ETCD_SERVERS.*#KUBE_ETCD_SERVERS=\"--etcd_servers=http://master:4001\"#" /etc/kubernetes/config

cp kubelet /etc/kubernetes/kubelet

for SERVICES in docker kube-proxy kubelet; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
done