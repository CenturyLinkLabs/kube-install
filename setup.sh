#!/bin/sh

set -x

for line in `cat`; do
   eval $line
done

pkey=`echo -e $MASTER_PRIVATE_KEY | base64 --decode`
echo -e "$pkey" > id_rsa
chmod 400 id_rsa

echo $MINION_IPS
echo $MASTER_IP

cat id_rsa

scp -o StrictHostKeyChecking=no  -i id_rsa install.sh root@$MASTER_IP:~/
ssh -o StrictHostKeyChecking=no  -i id_rsa root@$MASTER_IP  "cd ~/ && chmod +x install.sh && ./install.sh -master_ip=$MASTER_IP -minions=$MINION_IPS"
