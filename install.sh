#!/bin/bash

echo -e "Logged into Master node. Installing kubernetes on Master and Minions."

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
    -uname=*)
    uname="${i#*=}";;
esac
done

ROOT_USER="root"  #for brightbox, its fedora for fedora systems

#setup ssh logins from master to minions
IFS=","
minion_ips=( $MINION_IPS )

#Install ansbile
#Add epel repo
echo Installing wget and git
#sudo yum -y update
sudo yum install -y wget git
wget -q http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
sudo rpm -Uvh --quiet epel-release-7*.rpm
sudo yum install -q -y gcc python2-devel

echo Install Ansible
sudo easy_install pip
sudo pip -q install paramiko PyYAML Jinja2 httplib2 ansible

#Get Kubernetes ansible repo

git clone -q https://github.com/eparis/kubernetes-ansible.git
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
    ssh -o StrictHostKeyChecking=no  -t -t $uname@$ip "sudo yum -y remove docker && \
     sudo yum-config-manager --enable rhui-REGION-rhel-server-extras && \
     sudo yum -y install docker && \
     sudo systemctl start docker"
    minion_kuber_inv="$ip   kube_ip_addr=10.0.1.1\n$minion_kuber_inv"
done

echo $minion_kuber_inv

ssh -o StrictHostKeyChecking=no  -t -t $uname@$master_ip  "sudo yum -y remove docker && \
     sudo yum-config-manager --enable rhui-REGION-rhel-server-extras && \
     sudo yum -y install docker && \
     sudo systemctl start docker"

echo -e "[masters]
$master_ip

[etcd]
$master_ip

[minions]
$minion_kuber_inv" > inventory

cat inventory

sudo sed -i "s#ansible_ssh_user.*#ansible_ssh_user: $uname#" group_vars/all.yml

echo Setting up kubernetes cluster

ansible-playbook -i inventory setup.yml
systemctl | grep -i kube

echo Kubernetes cluster setup complete.

exit 0;
