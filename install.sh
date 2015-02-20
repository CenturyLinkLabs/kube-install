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
    MINION_IPS="${i#*=}";;
    -uname=*)
    uname="${i#*=}";;
esac
done

IFS=","
minion_ips=( $MINION_IPS )

for ip in "${minion_ips[@]}"
do
    ssh -o StrictHostKeyChecking=no  -t -t $uname@$ip "echo ."
    sudo ./master.sh -master-ip=$master_ip -minion-ip=$ip
done

for ip in "${minion_ips[@]}"
do
    scp -o StrictHostKeyChecking=no  -i id_rsa -r * $uname@$ip:~/
    ssh -o StrictHostKeyChecking=no  -t -t $uname@$ip "sudo ./minion.sh -master-ip=$master_ip -minion-ip=$ip"
done

echo Kubernetes cluster setup complete.

exit 0;

