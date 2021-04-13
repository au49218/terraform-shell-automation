sudo yum install -y epel-release nano yum-utils unzip wget
sudo bash -c 'cat << EOF > /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF'
sudo yum -y install MariaDB-server MariaDB-client
sudo service mariadb restart
