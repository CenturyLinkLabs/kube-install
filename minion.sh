#!/bin/bash

set -x

for i in "$@"
do
echo $i
case `echo $i | tr '[:upper:]' '[:lower:]'` in
    -master-ip=*)
    ma_ip="${i#*=}";;
    -minion-ip=*)
    mi_ip="${i#*=}";;
    -uname=*)
    un="${i#*=}";;
    -minion-name=*)
    mi_nm="${i#*=}";;
esac
done

chmod +x install_components.sh
sudo ./install_components.sh

/sbin/iptables -I INPUT 1 -p tcp --dport 10250 -j ACCEPT -m comment --comment "kubelet"
systemctl enable iptables-services
systemctl restart iptables-services

echo -e "\n$ma_ip master\n$mi_ip $mi_nm" >> /etc/hosts

sudo systemctl stop docker
sudo ip link delete docker0 #so that flannel is used.

sudo ./flannel.sh $mi_ip

sed -i s#KUBELET_HOSTNAME.*#KUBELET_HOSTNAME=\"--hostname_override=$mi_nm\"# kubelet
cp kubernetes-config /etc/kubernetes/config
cp kubelet /etc/kubernetes/kubelet

for SERVICES in flanneld docker kube-proxy kubelet; do
    systemctl restart $SERVICES
    systemctl enable  $SERVICES
    systemctl status  $SERVICES
done

service iptables save