
# install packages
sudo yum -y install epel-release nano yum-utils unzip wget expect

# create repo to install nginx
sudo bash -c 'cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF'

# install nginx
sudo yum -y install nginx

# get the private and public ip addresses
INTERNET_IP=$(hostname -I)
EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
echo "Internal IP: $INTERNET_IP"
echo "External IP: $EXTERNAL_IP"

# configure joomla on nginx
# note: use public ip of joomla-web server as server_name
sudo bash -c 'cat << EOF > /etc/nginx/conf.d/my.joomla.site.conf
server {
    listen 80;
    server_name EXTERNAL_IP;
    root /var/www/my.joomla.site;

    index index.html index.htm index.php;

    charset utf-8;

    access_log /var/log/nginx/my.joomla.site.access.log;
    error_log /var/log/nginx/my.joomla.site.error.log info;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~* /(images|cache|media|logs|tmp)/.*\.(php|pl|py|jsp|asp|sh|cgi)\$ {
        return 403;
        error_page 403 /403_error.html;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF'

# replace text EXTERNAL_IP with a variable in conf file
sudo sed -i "s/EXTERNAL_IP/${EXTERNAL_IP}/g" /etc/nginx/conf.d/my.joomla.site.conf

# test nginx configuration
sudo nginx -t

# disable SELinux
sudo setenforce 0

# restart nginx service
sudo systemctl restart nginx

# show nginx service status
sudo systemctl status nginx

# install php 7.1
sudo rpm -Uhv https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php71
sudo yum -y install php-fpm php-cli php-gd php-opcache php-mysqlnd php-json php-mcrypt php-xml php-curl

# replace text apache with a nginx in conf file
sudo sed -i "s/user = apache/user = nginx/g" /etc/php-fpm.d/www.conf
sudo sed -i "s/group = apache/group = nginx/g" /etc/php-fpm.d/www.conf

# fix session and cache directories permissions
sudo chown -R root:nginx /var/lib/php/*

# restart php fpm service
sudo systemctl restart php-fpm
sudo systemctl status php-fpm

# install joomla on centos
wget -O Joomla_3-8-5-Stable-Full_Package.zip https://downloads.joomla.org/us/cms/joomla3/3-8-5/Joomla_3-8-5-Stable-Full_Package.zip
sudo mkdir -p /var/www/my.joomla.site
sudo unzip -o -q Joomla_3-8-5-Stable-Full_Package.zip -d /var/www/my.joomla.site
sudo chown -R nginx: /var/www/my.joomla.site
sudo systemctl restart nginx
sudo systemctl status nginx
sudo systemctl restart php-fpm
sudo systemctl status php-fpm
#rm -rf Joomla_3-8-5-Stable-Full_Package.zip

# browse joomla-web public ip to configure further
echo "Visit http://$EXTERNAL_IP/installation/index.php in browser to configure joomla with localhost $INTERNET_IP"
