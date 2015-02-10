#!/bin/bash

key_start="\n----BEGIN PANAMAX DATA----"
key_end="----END PANAMAX DATA----\n"


echo "Installing Kubernetes on cluster"

for line in `cat`; do
   echo -e "$key_start\n$line\n$key_end"
   eval $line
done

if [[ "$MINION_IPS" == "" || "$MASTER_PUBLIC_IP" == "" || "$MASTER_PRIVATE_IP" == "" || "$MASTER_PRIVATE_KEY" == "" ]]; then
   echo "Missing Data  Master PRIVATE IP: $MASTER_PRIVATE_IP, Mster Public IP: $MASTER_PUBLIC_IP, Minion IPs: $MINION_IPS, Master Pkey: $MASTER_PRIVATE_KEY"
   exit 1;
fi

echo -e "$key_start\nAGENT_KUBER_API=http://$MASTER_PRIVATE_IP:8080\n$key_end"



if [[ "$RHEL_LOGIN_USER" == "" ]]; then
    RHEL_LOGIN_USER="root"
fi

pkey=`echo -e $MASTER_PRIVATE_KEY | base64 --decode`
echo -e "$pkey" > id_rsa
chmod 400 id_rsa


echo "Installing kubernetes over ssh"
scp -o StrictHostKeyChecking=no  -i id_rsa install.sh $RHEL_LOGIN_USER@$MASTER_PUBLIC_IP:~/
ssh -o StrictHostKeyChecking=no  -t -t -i id_rsa $RHEL_LOGIN_USER@$MASTER_PUBLIC_IP  "chmod +x install.sh && ./install.sh -master_ip=$MASTER_PRIVATE_IP -minions=$MINION_IPS -uname=$RHEL_LOGIN_USER"

echo "Remote kubernetes cluster deployment complete."

exit 0

