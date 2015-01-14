#!/bin/bash
set -x

#centos 6 did not work
#bbox: fed20,
#clc: rhel7

##Read stdin##


for i in "$@"
do
case `echo $i | tr '[:upper:]' '[:lower:]'` in
    -master_ip)
    MASTER_IP="${i#*=}";;
    -minions)
    MINION_IPS="${i#*=}";;
esac
done

ROOT_USER="root"  #for brightbox, its fedora for fedora systems

#setup ssh logins from master to minions
master_ip=$MASTER_IP
IFS=","
minion_ips=( $MINION_IPS )

#Install ansbile
#Add epel repo
yum install -y wget
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
sudo rpm -Uvh epel-release-7*.rpm
#Install Ansible
yum install -y ansible git

#Get Kubernetes ansible repo
git clone https://github.com/eparis/kubernetes-ansible.git
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
    minion_kuber_inv="$ip   kube_ip_addr=10.0.1.1\n$minion_kuber_inv"
done

echo -e "[masters]
$master_ip

[etcd]
$master_ip

[minions]
$minion_kuber_inv" > inventory

cat inventory

#Had to put private ips in inventory file
#edit group_vars/all.yml add ansible_ssh_user: root (for bbbox: fedora)
if [[ "$host" == "brightbox" ]]; then
    sed -i "s#ansible_ssh_user.*#ansible_ssh_user: fedora#g" group_vars/all.yml
fi

ansible-playbook -i inventory ping.yml
ansible-playbook -i inventory setup.yml

systemctl | grep -i kube
