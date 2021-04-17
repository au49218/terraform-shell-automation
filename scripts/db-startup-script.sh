
# remove mariadb packages including configuration files
# sudo yum -y remove mariadb mariadb-server && sudo rm -rf /var/lib/mysql /etc/my.cnf

# install packages
# sudo yum -y install epel-release nano yum-utils unzip wget expect

# create repo to install mariadb
sudo bash -c 'cat << EOF > /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF'

# install mariadb packages
sudo yum -y install MariaDB-server MariaDB-client

# restart mariadb service
sudo systemctl restart mariadb
sudo systemctl status mariadb

# secure the database
#Enter current password for root (enter for none):
#Set root password? [Y/n] Y
#New password:
#Re-enter new password:
#Remove anonymous users? [Y/n] Y
#Disallow root login remotely? [Y/n] Y
#Remove test database and access to it? [Y/n] Y
#Reload privilege tables now? [Y/n] Y

USER_ROOT='root'
CURRENT_MYSQL_PASSWORD=""
NEW_MYSQL_PASSWORD="abc"

SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$CURRENT_MYSQL_PASSWORD\r\"
expect \"root password?\"
send \"y\r\"
expect \"New password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$NEW_MYSQL_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

sudo echo "${SECURE_MYSQL}"

mysql -u$USER_ROOT -p$NEW_MYSQL_PASSWORD <<- 'EOF'
CREATE DATABASE joomla;
#GRANT ALL PRIVILEGES ON joomla.* TO 'joomla'@'localhost' IDENTIFIED BY 'strongpassword';
GRANT ALL PRIVILEGES ON joomla.* TO 'joomla'@'%' IDENTIFIED BY 'strongpassword';
SHOW DATABASES;
SELECT USER FROM mysql.user;
SHOW GRANTS FOR joomla;
FLUSH PRIVILEGES;
EOF
