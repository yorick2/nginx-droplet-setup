# requirements:
# set permissions of robots.txt in ~/server_files 
# change password in ~/server_files/local.xml
#   sudo chown juno:root /var/www
# add juno into www group
# 	sudo usermod -aG 33 juno
# chown var and media to www-data:www-data
#   sudo chown www-data:www-data media var
#


. setup_files/settings;

echo ; echo ;
echo 'please type a droplet url';
read url ;

echo ;
sqlfile=$(ls *sql) ;
echo $sqlfile
echo 'is this your database file [y/n]';
read useSqlFile ;
# if dev not set right ;
if [ "$useSqlFile" != "y" ] && [ "$useSqlFile" != "n" ]  ; then
  echo 'not valid answer please try again';
  exit ;
fi
if [ "$useSqlFile" == "n"  ] ; then \
  echo 'please enter the name of the sql file' ;
  read dbfile ;
else
 dbfile=$sqlfile ;
fi;
db="${dbfile##*/}";
db="${db%.sql}";

echo 'developement site? [y/n]' ;
read dev ;
# if dev not set right ;
if [ "$dev" != "y" ] && [ "$dev" != "n" ] ; then
  echo 'not valid answer please try again';
  exit ;
fi;
if [ "$dev" != "y" ]; then
	echo 'this is a dev site, we will add a robots.txt file'
fi;

# import db ;
echo '-->creating db';
mysql -u${mysqluser} -p${mysqlpassword} -e"create database ${db}" ;
echo '-->importing db';
mysql -u${mysqluser} -p${mysqlpassword} ${db} < ${dbfile} ;

# update database
echo '-->updating db';
table='core_config_data' ;

cmd="update ${db}.${table} set value='http://${url}/' where path='web/unsecure/base_url';";
mysql -u${mysqluser} -p${mysqlpassword} -e"${cmd}";

cmd="update ${db}.${table} set value='http://${url}/' where path='web/secure/base_url';";
mysql -u${mysqluser} -p${mysqlpassword} -e"${cmd}";

# make folder structure
echo '-->making web folder';
folder="/var/www/${url}/htdocs" ;
mkdir -p $folder ;

echo '-->making var and media folders';
mkdir -m 774 $folder/media;
mkdir -m 774 $folder/var;


echo '-->adding app/etc/local.xml';
mkdir $folder/app ;
mkdir $folder/app/etc ;
cp "setup_files/local.xml" ${folder}/app/etc/local.xml ;
sudo sed -i "s/mysqluser/${mysqluser}/g"  "${folder}/app/etc/local.xml"  ;
sudo sed -i "s/mysqlpassword/${mysqlpassword}/g"  "${folder}/app/etc/local.xml"  ;
sudo sed -i "s/database_name/${db}/g"  "${folder}/app/etc/local.xml"  ;
echo "<?php echo 'your <strong>"${url}"</strong> droplet is setup'  ?>" > ${folder}/index.php ;

echo '-->adding .htaccess';
cp "setup_files/htaccess" ${folder}/.htaccess ;

if [ dev=='y'  ] ; then \
	echo '-->adding robots.txt';
	cp "setup_files/robots.txt" ${folder}/robots.txt ;
fi ;

# setup vhost
echo '-->changing nginx webroot';
folder='/etc/nginx/sites-available';
sudo sed -i "s/droplet/${url}/g"  "${folder}/default"  ;
sudo service nginx restart;

echo ------successfully completed------ ;
echo 'dont forget to check robots.txt can be seen by google, by going to '${url}'/robots.txt'
