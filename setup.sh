#!/bin/bash
set -x

for line in `cat`; do
   eval $line
done

if [[ "$MINION_IPS" == "" || "$MASTER_PUBLIC_IP" == "" || "$MASTER_PRIVATE_IP" == "" || "$MASTER_PRIVATE_KEY" == "" ]]; then
   echo "Missing Data  Master PRIVATE IP: $MASTER_PRIVATE_IP, Mster Public IP: $MASTER_PUBLIC_IP, Minion IPs: $MINION_IPS, Master Pkey: $MASTER_PRIVATE_KEY"
   exit 1
fi

pkey=`echo -e $MASTER_PRIVATE_KEY | base64 --decode`
echo -e "$pkey" > id_rsa
chmod 400 id_rsa

scp -o StrictHostKeyChecking=no  -i id_rsa install.sh root@$MASTER_PUBLIC_IP:~/
ssh -o StrictHostKeyChecking=no  -i id_rsa root@$MASTER_PUBLIC_IP  "cd ~/ && chmod +x install.sh && ./install.sh -master_ip=$MASTER_PRIVATE_IP -minions=$MINION_IPS"


