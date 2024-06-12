#!/bin/bash
echo "------------------------Start------------------------------"
sudo su
yum -y update
yum -y install httpd
echo "<html><body bgcolor=black><center><h2><p><font color=red>WebServer_AWS_High_Availability</h2></center></body></html>"  >  /var/www/html/index.html
PrivatIp=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "This is my Ip" $PrivatIp >> /var/www/html/index.html
sudo service httpd start
chkconfig httpd on
echo "UserData executed on $(date)" >> /var/www/html/log.txt
echo "------------------------FINISH-----------------------------"
#