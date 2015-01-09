#!/bin/bash
set -x
set -e

OS="RHEL7"
#centos 6 did not work
#bbox: fed20,
#clc: rhel7

#setup ssh logins from master to minions
master_ip="10.90.174.37"
minion_ips=( "10.90.174.38" "10.90.174.39" )

user_id="root"
minion_kuber_inv=""
for ip in "${minion_ips[@]}"
do
    minion_kuber_inv="$ip   kube_ip_addr=10.0.1.1\n$minion_kuber_inv"
done

#install ansbile
#Add epel repo
yum install -y wget
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
sudo rpm -Uvh epel-release-7*.rpm
#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#sudo rpm -Uvh epel-release-6*.rpm
yum install -y ansible git

git clone https://github.com/eparis/kubernetes-ansible.git
cd kubernetes-ansible

#Removing rhel repos as they seem to need subscription, but removing these dont seem to be causing any issues
if [[ "$OS" == "RHEL7" ]]; then
echo "---
- name: Enable the RHEL7 Kubernetes copr repo
  copy: src=eparis-kubernetes-epel-7.repo dest=/etc/yum.repos.d/eparis-kubernetes-epel-7.repo

- name: Enable eparis extra repo
  copy: src=eparis-extras.repo dest=/etc/yum.repos.d/eparis-extras.repo "  > roles/common/tasks/rhel7_repos.yml
fi

#Generating inventory file for ansible
echo -e "[masters]
$master_ip

[etcd]
$master_ip

[minions]
$minion_kuber_inv" > inventory

#Had to put private ips in inventory file
#edit group_vars/all.yml add ansible_ssh_user: root (for bbbox: fedora)
if [[ "$host" == "brightbox" ]]; then
    sed -i "s#ansible_ssh_user.*#ansible_ssh_user: fedora#g" group_vars/all.yml
fi

ansible-playbook -i inventory ping.yml
ansible-playbook -i inventory setup.yml

systemctl | grep -i kube