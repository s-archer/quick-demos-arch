#!/bin/bash
# Send all command output to /var/log/user-data.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/user-data-out.log 2>&1

echo "--- START -- $(date) ---"
echo ""
echo "--- UPDATE YUM ---"
yum update -y
echo "--- INSTALL JAVA ---"
yum install -y java-1.8.0-openjdk 
# Install ElasticStack 
echo "--- IMPORT ELASTIC RPM ---"
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch -y 
echo "--- UPDATE YUM REPO TO INCLUDE ELASTIC ---"
cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF
echo "--- INSTALL ELASTIC ---"
yum install -y --enablerepo=elasticsearch elasticsearch
echo "--- CONFIG ELASTIC LISTEN ALL INTERFACES ---"
cat <<EOF > /etc/elasticsearch/elasticsearch.yml
network.host: 0.0.0.0
EOF
echo "--- RELOAD DAEMONS ---"
systemctl daemon-reload
echo "--- ENABLE ELASTIC ---"
systemctl enable elasticsearch.service
echo "--- START ELASTIC ---"
systemctl start elasticsearch.service
echo "--- SLEEP 20 ---"
sleep 20
# Install Logstash & Kibana
echo "--- UPDATE YUM REPO TO INCLUDE LOGSTASH ---"
cat <<EOF > /etc/yum.repos.d/elastic.repo
[Elastic]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
#echo "--- INSTALL LOGSTASH ---"
#yum install logstash -y
#echo "--- ENABLE LOGSTASH ---"
#systemctl enable logstash
#echo "--- START LOGSTASH ---"
#systemctl start logstash

# Install Kibana
echo "--- INSTALL KIBANA ---"
yum install kibana -y
echo "--- CREATE SSL KEY/CERT FOR KIBANA ---"
openssl req -newkey rsa:2048 -nodes -keyout  /etc/ssl/certs/key.pem -x509 -days 365 -out  /etc/ssl/certs/certificate.pem -subj "/C=GB/ST=LONDON/L=LONDON/O=F5/OU=UKSE/CN=kibana.f5demo.com/emailAddress=arch@f5demo.com"
echo "--- CONFIGURE KIBANA YAML FILE ---"
cat <<EOF > /etc/kibana/kibana.yml
server.host: 0.0.0.0
server.ssl.enabled: true
server.ssl.key: /etc/ssl/certs/key.pem
server.ssl.certificate: /etc/ssl/certs/certificate.pem
EOF
echo "--- ENABLE KIBANA ---"
systemctl enable kibana
echo "--- START KIBANA ---"
systemctl start kibana
echo "--- DONE -- $(date) ---"