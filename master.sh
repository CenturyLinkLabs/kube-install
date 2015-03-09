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
    -minions=*)
    mis="${i#*=}";;
    -uname=*)
    un="${i#*=}";;
esac
done

chmod +x ./install_components.sh
sudo ./install_components.sh

echo -e "\n$ma_ip master" >> /etc/hosts

IFS=","
mi_ips=( $mis )
i=1
mi_nms=""

for ip in "${mi_ips[@]}"
do
    nm="minion$i"
    echo -e "\n$ip $nm" >> /etc/hosts
    if [[ "$mi_nms" == "" ]]; then
        mi_nms=$nm
    else
        mi_nms="$mi_nms,$nm"
    fi
    (( i++ ))
done

echo "KUBELET_ADDRESSES=\"--machines=$mi_nms\"" > controller-manager
cp etcd-kube.service /usr/lib/systemd/system/
sudo systemctl restart etcd-kube

curl -s -L http://master:4001/v2/keys/coreos.com/network/config -XPUT -d value='{"Network": "10.254.0.0/16", "SubnetLen": 24, "Backend": {"Type": "udp"}}'
sudo ./flannel.sh $ma_ip

cp kubernetes-config /etc/kubernetes/config
cp apiserver  /etc/kubernetes/apiserver
cp controller-manager /etc/kubernetes/controller-manager

for SERVICES in kube-apiserver kube-controller-manager kube-scheduler; do
    systemctl restart $SERVICES
    systemctl enable $SERVICES
    systemctl status $SERVICES
done

i=1
for ip in "${mi_ips[@]}"
do
    nm="minion$i"
    scp -o StrictHostKeyChecking=no -i id_rsa -r * $un@$ip:~/
    ssh -o StrictHostKeyChecking=no -i id_rsa -t -t $un@$ip "sudo ./minion.sh -master-ip=$ma_ip -minion-ip=$ip -uname=$un -minion-name=$nm"
    (( i++ ))
done


exit 0;
