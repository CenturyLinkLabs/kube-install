#!/bin/bash

echo "Installing Kubernetes on cluster"

for line in `cat`; do
   eval $line
done

if [[ "$MINION_IPS" == "" || "$MASTER_PUBLIC_IP" == "" || "$MASTER_PRIVATE_IP" == "" || "$MASTER_PRIVATE_KEY" == "" ]]; then
   echo "Missing Data  Master PRIVATE IP: $MASTER_PRIVATE_IP, Mster Public IP: $MASTER_PUBLIC_IP, Minion IPs: $MINION_IPS, Master Pkey: $MASTER_PRIVATE_KEY"
   exit 1;
fi

echo -e "\n----BEGIN PANAMAX DATA----"
echo -e "\nAGENT_KUBER_API=http://$MASTER_PRIVATE_IP:8080"
echo -e "\n----END PANAMAX DATA----"


pkey=`echo -e $MASTER_PRIVATE_KEY | base64 --decode`
echo -e "$pkey" > id_rsa
chmod 400 id_rsa


echo "Installing kubernetes over ssh"
scp -o StrictHostKeyChecking=no  -i id_rsa install.sh root@$MASTER_PUBLIC_IP:~/
ssh -o StrictHostKeyChecking=no  -t -t -i id_rsa root@$MASTER_PUBLIC_IP  "chmod +x install.sh && ./install.sh -master_ip=$MASTER_PRIVATE_IP -minions=$MINION_IPS"

echo "Remote kubernetes cluster deployment complete."

exit 0


