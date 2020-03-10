#!/bin/bash
# Send all command output to /var/log/user-data.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/user-data-out.log 2>&1

echo "--- START USER DATA INSTALL SCRIPT -- $(date) ---"
echo ""
#echo "--- UPDATE YUM ---"
#yum update -y
cd /home/centos

echo "--- ADD DOCKER REPO TO YUM ---"
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

echo "--- INSTALL WGET & ADD EPEL REPO ---"
yum install -y wget
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y ./epel-release-latest-*.noarch.rpm 

echo "--- INSTALL PACKAGES ---"
yum install -y gcc \
  python-devel \
  python-pip \
  git \
  yum-utils \
  device-mapper-persistent-data \
  lvm2 \
  docker-ce \
  docker-ce-cli \
  containerd.io

echo "--- ENABLE & START DOCKER ---"
systemctl enable docker
systemctl start docker

echo "--- UPGRADE PIP ---"
pip install --upgrade --force-reinstall pip==9.0.3

echo "--- INSTALL DOCKER COMPOSE & ZIPP ---"
pip install docker-compose zipp

echo "--- CLONE ELK REPO ---"
git clone https://github.com/deviantony/docker-elk.git

echo "--- START ELK CONTAINERS ---"
cd docker-elk
docker-compose up -d

echo "--- CREATE NGINX CONFIG ---"
cat <<EOF > /etc/nginx/conf.d/kibana.conf
server {
    listen 8008;
 
    location / {
        proxy_pass http://127.0.0.1:5601;
    }
}
EOF
echo "--- REMOVE NGINX DEFAULT CONFIG ---"
rm /etc/nginx/conf.d/default.conf
echo "--- SLEEP 10 ---"
sleep 10
echo "--- RELOAD NGINX ---"
nginx -s reload
echo "--- MODIFY SELINUX TO ALLOW NGINX TO PROXY KIBANA ---"
setsebool -P httpd_can_network_connect 1

echo "--- END USER DATA INSTALL SCRIPT -- $(date) ---"