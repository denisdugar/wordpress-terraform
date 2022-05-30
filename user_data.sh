#!/bin/bash
sudo apt update
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip \
                 nfs-common \
                 cifs-utils \
                 curl \
                 mysql-client-core-8.0 
sudo mkdir /var/www
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_endpoint}:/ /var/www
curl https://wordpress.org/latest.tar.gz | sudo tar zx -C /var/www
echo "<VirtualHost *:80>
    DocumentRoot /var/www/wordpress
    <Directory /var/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /var/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>" | sudo tee -a /etc/apache2/sites-available/wordpress.conf
mysql -h ${db_endpoint} -P 3306 -u ${db_username} -p${db_password} -e "CREATE DATABASE wordpress"
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo a2dissite 000-default
sudo systemctl restart apache2
sudo cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
sudo sed -i 's/database_name_here/wordpress/' /var/www/wordpress/wp-config.php
sudo sed -i 's|username_here|'${db_username}'|' /var/www/wordpress/wp-config.php
sudo sed -i 's|password_here|'${db_password}'|' /var/www/wordpress/wp-config.php
sudo sed -i 's|localhost|'${db_endpoint}'|' /var/www/wordpress/wp-config.php
sudo systemctl restart apache2
