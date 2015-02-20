#!/bin/bash


function log_key {
    if [[ "$#" == "2" ]]; then
        c="$1=$2"
    else
        c="$1"
    fi
    echo -e "\n----BEGIN PANAMAX DATA----\n$key_start\n$c\n----END PANAMAX DATA----\n"
}

echo "Installing Kubernetes on cluster"

for line in `cat`; do
   log_key $line
   eval $line
done

if [[ "$MINION_IPS" == "" || "$MASTER_PUBLIC_IP" == "" || "$MASTER_PRIVATE_IP" == "" || "$MASTER_PRIVATE_KEY" == "" ]]; then
   echo "Missing Data  Master PRIVATE IP: $MASTER_PRIVATE_IP, Mster Public IP: $MASTER_PUBLIC_IP, Minion IPs: $MINION_IPS, Master Pkey: $MASTER_PRIVATE_KEY"
   exit 1;
fi

log_key  "AGENT_KUBER_API" "http://$MASTER_PRIVATE_IP:8080"

if [[ "$RHEL_LOGIN_USER" == "" ]]; then
    RHEL_LOGIN_USER="root"
fi

pkey=`echo -e $MASTER_PRIVATE_KEY | base64 --decode`
echo -e "$pkey" > id_rsa
chmod 400 id_rsa

echo "Installing kubernetes over ssh"
scp -o StrictHostKeyChecking=no  -i id_rsa -r * $RHEL_LOGIN_USER@$MASTER_PUBLIC_IP:~/
scp -o StrictHostKeyChecking=no  -i id_rsa -r kubernetes-ansible $RHEL_LOGIN_USER@$MASTER_PUBLIC_IP:~/
ssh -o StrictHostKeyChecking=no  -t -t -i id_rsa $RHEL_LOGIN_USER@$MASTER_PUBLIC_IP  "chmod +x install.sh && ./install.sh -master_ip=$MASTER_PRIVATE_IP -minions=$MINION_IPS -uname=$RHEL_LOGIN_USER"

echo "Remote kubernetes cluster deployment complete."
exit 0
