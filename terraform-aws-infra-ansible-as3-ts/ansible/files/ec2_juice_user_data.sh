#!/bin/bash
# Send all command output to /var/log/user-data.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/user-data-out.log 2>&1

echo "--- START -- $(date) ---"
echo ""
echo "--- UPDATE YUM ---"
yum update -y
echo "--- INSTALL DOCKER ---"
yum install -y docker
echo "--- START DOCKER ---"
service docker start
echo "--- DOCKER PULL JUICE SHOP ---"
docker pull bkimminich/juice-shop
echo "--- DOCKER RUN JUICE SHOP ---"
docker run -d -p 8008:3000 bkimminich/juice-shop
echo "--- CREATE NGINX CONFIG ---"
cat <<EOF > /etc/nginx/conf.d/arch.conf
server {
    listen 80;
 
    location / {
        proxy_pass http://127.0.0.1:8008;
    }
}
EOF
echo "--- REMOVE NGINX DEFAULT CONFIG ---"
rm /etc/nginx/conf.d/default.conf
echo "--- SLEEP 10 ---"
sleep 10
echo "--- RELOAD NGINX ---"
nginx -s reload
echo "--- DONE -- $(date) ---"