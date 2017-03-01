# ChurchCRM Guided Setup on DigitalOcean

You can use this script to install and setup [ChurchCRM](http://churchcrm.io) on [DigitalOcean](https://m.do.co/c/6cf4df89b226) as well as setup SSL for your domain through LetsEncrypt.

## How To Use

### Get a DigitalOcean Account

If you don't already have a DigitalOcean account, you can open an account and **get $10 in credit** through this link: [Click Here to Get $10 Credit at DigitalOcean](https://m.do.co/c/6cf4df89b226) - This helps YOU and it helps ME out too... so please do!

### Create a Droplet

Once you have an account, Create a new Droplet from a One-Click app based on **"LAMP on 16.04"** or **"Wordpress 4.7 on 16.04"**.

The minimum size droplet for LAMP 16.04 is the $5/month option. If you choose to create a Wordpress site, you must choose a minimum of $10/month.

### Point Your Domain Name to Your Droplet

Now point your Domain Name to your newly created droplet. You can read more about how to do this here. https://cloud.digitalocean.com/support/suggestions?article=how-to-set-up-a-host-name-with-digitalocean&i=0dea53&page=0&query=Domain%20Name

### Connect Through SSH

Once done, log into DigitalOcean through SSH. You can find information on how to do that here. https://www.digitalocean.com/community/tutorials/how-to-connect-to-your-droplet-with-ssh

### ChurchCRM installation

Once logged in as `root`, you are ready to install ChurchCRM! Clone this repository with the following command: *(type this into the console/terminal)*

`git clone https://github.com/jaskipper/DO-ChurchCRM-Installer.git`

When finished, run the installer with the following command to begin the guided installation.

`DO-ChurchCRM-Installer/install.sh`

Towards the end of the installation you will be asked to setup SSL Encryption for your server. Be sure to put your base domain or subdomain name without "www" or "http://" (example `mychurch.com`, `crm.mychurch.com`). You also can leave the install location as default (/var/www/churchcrm).

Answer the questions as they are asked, and in the LetsEncrypt Setup, I recommend that you choose `"Secure:  Make all requests redirect to secure HTTPS access"`.

### Getting Started With ChurchCRM

Once finalized, you can test your ChurchCRM installation by going to your domain. (ex. https://mychurch.com, https://crm.mychurch.com)

You can find more information at ChurchCRM's website (http://churchcrm.io) and their GitHub account (https://github.com/ChurchCRM/CRM).
