#!/bin/bash
echo ""
echo "#   Installing Latest ChurchCRM and Dependencies    #"
echo ""

DEBIAN_FRONTEND=noninteractive apt
apt --yes update
apt --yes install unzip jq

#Download Latest Stable release
if (curl -sOL "$(jq -r ".assets[] | .browser_download_url" < <( curl -s "https://api.github.com/repos/churchCRM/CRM/releases/latest" ))"); then
  echo "Downloaded Successfully!"
  crmzip=( basename "ChurchCRM-*" )
  unzip $crmzip -d /var/www
  rm $crmzip
else
  echo -e "ChurchCRM was \e[31mNOT\e[0m able to Download Successfully. I will go ahead and install all of the nessesary depencencies in order to allow it to run once it is installed successfully. You can try running this script again by changing directories into the 'install-files' directory and running '\e[31m./churchcrm\e[0m' If it continues to fail, you have several other options.

  1) Go to the releases page at ChurchCRM's github account (https://github.com/ChurchCRM/CRM/releases) and get the download link to the latest release (Right click on the latest zip file and 'copy link'). Once this is install process is over, you can enter the following commands.
\e[31m
  cd /var/www
  wget https://github.com/ChurchCRM/CRM/releases/download/2.4.2/ChurchCRM-2.4.2.zip (Or whatever the latest file link is)
  unzip Church*.zip
  chown -R www-data:www-data churchcrm
  chmod -R 755 churchcrm
  find ./churchcrm/. -type f -exec chmod 644 {} +
\e[0m

  2) You can also download the file directly to your computer and upload it through SFTP (Using an FTP Client like Filezilla). You want to make sure that you upload it to the /var/www folder."
fi

PKG_NAME=php7.0-mbstring
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $PKG_NAME|grep "install ok installed")
echo Checking for $PKG_NAME: $PKG_OK
if [ "" == "$PKG_OK" ]; then
  echo "No $PKG_NAME. Setting up $PKG_NAME."
  sudo apt --yes install $PKG_NAME
fi

PKG_NAME=php7.0-mcrypt
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $PKG_NAME|grep "install ok installed")
echo Checking for $PKG_NAME: $PKG_OK
if [ "" == "$PKG_OK" ]; then
  echo "No $PKG_NAME. Setting up $PKG_NAME."
  sudo apt --yes install $PKG_NAME
fi

echo ""
echo "#       Creating ChurchCRM User and Database        #"
echo ""

#Get MySQL Root Password and put it in a variable
rootdbpassword=$(grep root_mysql /root/.digitalocean_password | sed 's#"##g' | sed 's#root_mysql_pass=##g')

echo "Removing Root MySQL Configuration file"
if [ -f /root/.my.cnf ]; then
  rm /root/.my.cnf
fi

echo "Creating New Root MySQL Configuration file"
echo "[client]" >> /root/.my.cnf
echo "user=root" >> /root/.my.cnf
echo "password=$rootdbpassword" >> /root/.my.cnf

echo "Changing Permissions on Root MySQL Configuration file"
chmod 600 /root/.my.cnf

# Getting or Setting ChurchCRM Database Name
if grep -q CHURCHCRM_DATABASE /root/.digitalocean_password; then
  echo -e "It looks like you have already set up your database in MySQL. Getting that info now..."
  CHURCHCRM_DATABASE=$(grep CHURCHCRM_DATABASE /root/.digitalocean_password | sed 's#"##g' | sed 's#CHURCHCRM_DATABASE=##g')
else
  echo -e "Setting new ChurchCRM Database User and Password in MySQL"
  CHURCHCRM_DATABASE=churchcrm
  echo "CHURCHCRM_DATABASE=$CHURCHCRM_DATABASE" >> /root/.digitalocean_password
fi
export CHURCHCRM_DATABASE

# Getting or Setting ChurchCRM Database User
if grep -q CHURCHCRM_DB_USER /root/.digitalocean_password; then
  CHURCHCRM_DB_USER=$(grep CHURCHCRM_DB_USER /root/.digitalocean_password | sed 's#"##g' | sed 's#CHURCHCRM_DB_USER=##g')
else
  CHURCHCRM_DB_USER=churchcrm
  echo "CHURCHCRM_DB_USER=$CHURCHCRM_DB_USER" >> /root/.digitalocean_password
fi
export CHURCHCRM_DB_USER

# Getting or Setting ChurchCRM Database Random Password
if grep -q CHURCHCRM_DB_PASSWORD /root/.digitalocean_password; then
  CHURCHCRM_DB_PASSWORD=$(grep CHURCHCRM_DB_PASSWORD /root/.digitalocean_password | sed 's#"##g' | sed 's#CHURCHCRM_DB_PASSWORD=##g')
else
  CHURCHCRM_DB_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
  echo "CHURCHCRM_DB_PASSWORD=$CHURCHCRM_DB_PASSWORD" >> /root/.digitalocean_password
fi
export CHURCHCRM_DB_PASSWORD

echo -e "--------------------"
echo -e "You can find your ChurchCRM Database Username and Password in /root/.digitalocean_password"
echo -e "--------------------"

# Adding Database to MySQL
if (mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $CHURCHCRM_DATABASE;"); then
  CHURCHCRM_DATABASE=churchcrm
  echo "Database \"$CHURCHCRM_DATABASE\" created"
else
  echo "There was a problem installing the Database \"$CHURCHCRM_DATABASE\""
fi

#Adding Username and Password to MySQL
if (mysql -uroot -e "CREATE USER IF NOT EXISTS '$CHURCHCRM_DB_USER'@'localhost' IDENTIFIED BY '$CHURCHCRM_DB_PASSWORD';"); then
  CHURCHCRM_DB_USER=churchcrm
  CHURCHCRM_DB_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
  echo "User \"$CHURCHCRM_DB_USER\" created @localhost with password \"$CHURCHCRM_DB_PASSWORD\""
else
  echo "There was a problem adding the User \"$CHURCHCRM_DB_USER\""
fi

if (mysql -uroot -e "GRANT ALL PRIVILEGES ON $CHURCHCRM_DATABASE.* TO '$CHURCHCRM_DB_USER'@'localhost';"); then
  echo "Granting all privileges on \"$CHURCHCRM_DATABASE\" to '$CHURCHCRM_DB_USER'@'localhost'"
else
  echo "There was a problem granting privileges on the Database \"$CHURCHCRM_DATABASE\" to '$CHURCHCRM_DB_USER'@'localhost'"
fi
# Database Settings for ChurchCRM

mysql -uroot -e "FLUSH PRIVILEGES;"

echo "[mysqld]" >> /etc/mysql/conf.d/disable_strict_mode.cnf
echo "sql_mode=IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" >> /etc/mysql/conf.d/disable_strict_mode.cnf
service mysql restart

echo "Finished ChurchCRM Database setup successfully"

echo "Setting up ChurchCRM Config file"
cp /var/www/churchcrm/Include/Config.php.example /var/www/churchcrm/Include/Config.php

sed -i "s/||DB_SERVER_NAME||/$MYSQL_DB_HOST/g" /var/www/churchcrm/Include/Config.php
sed -i "s/||DB_NAME||/$CHURCHCRM_DATABASE/g" /var/www/churchcrm/Include/Config.php
sed -i "s/||DB_USER||/$CHURCHCRM_DB_USER/g" /var/www/churchcrm/Include/Config.php
sed -i "s/||DB_PASSWORD||/$CHURCHCRM_DB_PASSWORD/g" /var/www/churchcrm/Include/Config.php
sed -i "s/||URL||//g" /var/www/churchcrm/Include/Config.php
sed -i "s/||ROOT_PATH||//g" /var/www/churchcrm/Include/Config.php
chown www-data:www-data /var/www/churchcrm/Include/Config.php

export INSTALL_LOC="/var/www/churchcrm"

chown -R www-data:www-data $INSTALL_LOC
chmod -R 755 $INSTALL_LOC
find $INSTALL_LOC/. -type f -exec chmod 644 {} +

git clone https://github.com/jaskipper/DO-ssl-setup.git

DO-ssl-setup/sslsetup

echo "Successfully installed and Set up ChurchCRM!"

echo ""
echo "Here is your ChurchCRM Installation Information. PLEASE WRITE THIS DOWN IN A SECURE LOCATION!"
echo ""
echo "............................."
echo "ChurchCRM Username: admin"
echo "ChurchCRM Password: changeme"
echo "ChurchCRM Database User: $CHURCHCRM_DB_USER"
echo "ChurchCRM Database Password: $CHURCHCRM_DB_PASSWORD"
echo "ChurchCRM Database Name: $CHURCHCRM_DATABASE"
echo "ChurchCRM Database Host: localhost"
echo "............................."
