#!/bin/bash

set -x

echo -e "Logged into Master node. Installing kubernetes on Master and Minions."

for i in "$@"
do
echo $i
case `echo $i | tr '[:upper:]' '[:lower:]'` in
    -master_ip=*)
    master_ip="${i#*=}";;
    -minions=*)
    minions="${i#*=}";;
    -uname=*)
    uname="${i#*=}";;
esac
done

echo "KUBELET_ADDRESSES=\"--machines=$minions\"" > controller-manager
#sed -i s#MINION_ADDRESSES.*#MINION_ADDRESSES=\"$minions\"# apiserver

sudo ./master.sh -master-ip=$master_ip -minions=$minions

IFS=","
minion_ips=( $MINION_IPS )

for ip in "${minion_ips[@]}"
do
    scp -o StrictHostKeyChecking=no  -r * $uname@$ip:~/
    ssh -o StrictHostKeyChecking=no  -t -t $uname@$ip "sudo ./minion.sh -master-ip=$master_ip -minion-ip=$ip"
done

for SERVICES in docker kube-apiserver kube-controller-manager kube-scheduler kubectl; do
    sudo systemctl restart $SERVICES
    sudo systemctl enable $SERVICES
    sudo systemctl status $SERVICES
done


echo Kubernetes cluster setup complete.

exit 0;

