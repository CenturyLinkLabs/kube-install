#!/bin/bash

echo -e "Logged into master, setting up kubernetes on master and minions"

function runCmd {
    eval "$@" >/dev/null &
    PID=$!
    while $(kill -n 0 $PID 2> /dev/null)
    do
      #echo -n '.'
      sleep 2
    done
}

for i in "$@"
do
echo $i
case `echo $i | tr '[:upper:]' '[:lower:]'` in
    -master_ip=*)
    master_ip="${i#*=}";;
    -minions=*)
    MINION_IPS="${i#*=}";;
esac
done

ROOT_USER="root"  #for brightbox, its fedora for fedora systems

#setup ssh logins from master to minions
IFS=","
minion_ips=( $MINION_IPS )

#Install ansbile
#Add epel repo
echo Installing wget and git
runCmd "yum install -q -y wget git"
runCmd "wget -q http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm && sudo rpm -Uvh --quiet epel-release-7*.rpm"

echo Install Ansible
runCmd "yum install -q -y ansible"

#Get Kubernetes ansible repo
runCmd "git clone -q https://github.com/eparis/kubernetes-ansible.git"
cd kubernetes-ansible

#Removing rhel repos as they seem to need subscription, but removing these dont seem to be causing any issues
#if [[ "$OS" == "RHEL7" ]]; then #This can be always changed, will be used only when rhel 7 is being deployed.
echo "---
- name: Enable the RHEL7 Kubernetes copr repo
  copy: src=eparis-kubernetes-epel-7.repo dest=/etc/yum.repos.d/eparis-kubernetes-epel-7.repo

- name: Enable eparis extra repo
  copy: src=eparis-extras.repo dest=/etc/yum.repos.d/eparis-extras.repo "  > roles/common/tasks/rhel7_repos.yml
#fi

#Generating inventory file for ansible
minion_kuber_inv=""
for ip in "${minion_ips[@]}"
do
    ssh -o StrictHostKeyChecking=no  -t -t root@$ip  "echo hello"
    minion_kuber_inv="$ip   kube_ip_addr=10.0.1.1\n$minion_kuber_inv"
done

echo $minion_kuber_inv

ssh -o StrictHostKeyChecking=no  -t -t -i id_rsa root@$master_ip  "echo ."

echo -e "[masters]
$master_ip

[etcd]
$master_ip

[minions]
$minion_kuber_inv" > inventory

cat inventory

#Private IPs
#If root user id is not root, update in this file
if [[ "$host" == "brightbox" ]]; then
    sed -i "s#ansible_ssh_user.*#ansible_ssh_user: fedora#g" group_vars/all.yml
fi


echo Setting up kubernetes cluster

runCmd "ansible-playbook -i inventory setup.yml"
systemctl | grep -i kube

echo Kubernetes cluster setup complete.

exit 0;
