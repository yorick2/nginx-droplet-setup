#!/bin/bash

./setup_files/settings;


#######################################
#              questions
#######################################


echo ;
echo 'please type a droplet url';
read url ;

# import database 
echo 
echo 'Import a database file [y/n]';
read importsql ;
if [ "$importsql" != "y" ] && [ "$importsql" != "n" ]  ; then
	echo 'not valid answer please try again';
  exit ;
fi
if [ "$importsql" = "y" ]  ; then
	echo 
	echo 'is your database compressed (.tar.gz) and on the default remote server [y/n]'
	read dbOnDefaultRemoteServer 
	if [ "$dbOnDefaultRemoteServer" != "y" ] && [ "$dbOnDefaultRemoteServer" != "n" ]  ; then
	  echo 
	  echo 'not valid answer please try again';
	  exit ;
	fi
	# fetch from remote server
	if [ "$dbOnDefaultRemoteServer" = "y" ]  ; then
		echo 
		echo 'what is your compressed filename e.g. example.tar.gz'
		read tarDbFilename
	# local database file
	else
		sqlfile=$(ls *sql) ;
		echo 
		echo $sqlfile
		echo 'is this your database file [y/n]';
		read useSqlFile ;
		# if dev not set right ;
		if [ "$useSqlFile" != "y" ] && [ "$useSqlFile" != "n" ]  ; then
		  echo 'not valid answer please try again';
		  exit ;
		fi
		if [ "$useSqlFile" = "n" ]  ; then 
		  echo 
		  echo 'please enter the name of the sql file' ;
		  read dbfile ;
		else
		 	dbfile=$sqlfile ;
		fi;
	fi;
	db="${dbfile##*/}";
	db="${db%.sql}";
	dbexists=$(mysql -u${mysqluser} -p${mysqlpassword} --batch --skip-column-names -e "SHOW DATABASES LIKE '"${db}"';" | grep "${db}" > /dev/null; echo "$?")
	if [ $dbexists -eq 0 ];then
		echo "database name already used"
		exit
	fi;
fi;

# dev site?
echo 
echo 'developement site? [y/n]' ;
read dev ;
# if dev not set right ;
if [ "$dev" != "y" ] && [ "$dev" != "n" ] ; then
  echo 'not valid answer please try again';
  exit ;
fi;

# magento site?
echo 
echo 'magento site? [y/n]' ;
read magento ;
# if dev not set right ;
if [ "$magento" != "y" ] && [ "$magento" != "n" ] ; then
  echo 'not valid answer please try again';
  exit ;
fi;

# in git?
# git
echo  ;
echo 'Import a git repo? [y/n]';
read importgit ;
if [ "$importgit" != "y" ] && [ "$importgit" != "n" ]  ; then
  echo 'not valid answer please try again';
  exit ;
fi
if [ "$importgit" = "y" ]  ; then
	echo ;
	echo 'What is the https: git repo url? (it has to be the https one)' ;
	read giturl;
	echo ;
	echo 'does your git repo have a htdocs folder? [y/n]'
	read gitHtdocs ;
	echo 'does your repository use composer? [y/n]'
	read isComposer;
fi;



#######################################
#              actions 
#######################################


####### make main structure (without web folder) ########
echo '-->making main folder (without web folder)';
mkdir -p "/var/www/${url}/";


############ setup vhost #########
echo '-->changing nginx webroot';
sitesAvailibileFolder='/etc/nginx/sites-available';
sudo sed -i "s/droplet/${url}/g"  "${sitesAvailibileFolder}/default"  ;
sudo service nginx restart;


######## git ########
folder="/var/www/${url}/htdocs" ;
if [ "$importgit" = "y" ]  ; then
        if [ "$gitHtdocs" = "y" ]  ; then
                gitFolder=${folder%/htdocs}
        else
                gitFolder=${folder}
                echo '-->making web folder';
                mkdir -p ${folder} ;
        fi;
	echo '-->git clone '
	git clone ${giturl} ${gitFolder}
	if [ "$dev" != "y" ]; then
		git checkout develop;
	fi;
else
	echo '-->making web folder';
	mkdir -p ${folder} ;
fi;

######## database ######
if [ "$importsql" = "y" ]  ; then
	# fetch from remote server
	if [ "$dbOnDefaultRemoteServer" = "y" ]  ; then
		echo '-->downloading your compressed database';
		rsync --progress -ahzx ${remoteServerUser$}@${remoteServerHost}:${remoteServerFolder}/${tarDbFilename}  .
		echo '-->uncompressing your compressed database';
		tar -xzvf ${tarDbFilename}
		dbfile=${tarDbFilename%.tar.gz}.sql
	fi;
fi;
if [ "$importsql" = "y" ]  ; then
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
fi;


####### composer #######
if [ "$isComposer" = "y" ] ; then
	cd ${gitFolder} ;
	composer install;
	sudo chmod -R w+g var media;
fi;

if [ "$magento" = "y" ] ; then 

	######## make media & var folders #######
	echo '-->making var and media folders';
	mkdir -m 774 $folder/media;
	mkdir -m 774 $folder/var;

	####### app/etc/local.xml ######
	# make file
	echo '-->adding app/etc/local.xml';
	if [ "$importgit" = "n" ]  ; then
		mkdir $folder/app ;
		mkdir $folder/app/etc ;
	fi;
	# update db
	if [ "$importsql" = "y" ]  ; then
		cp "setup_files/local.xml" ${folder}/app/etc/local.xml ;
		sudo sed -i "s/mysqluser/${mysqluser}/g"  "${folder}/app/etc/local.xml"  ;
		sudo sed -i "s/mysqlpassword/${mysqlpassword}/g"  "${folder}/app/etc/local.xml"  ;
		sudo sed -i "s/database_name/${db}/g"  "${folder}/app/etc/local.xml"  ;
	fi;

	####### add standard htaccess #######
	echo '-->adding .htaccess';
	cp "setup_files/htaccess" ${folder}/.htaccess ;
fi;

if [ "$importgit" = "n" ]  ; then
	echo "<?php echo 'your <strong>"${url}"</strong> droplet is setup'  ?>" > ${folder}/index.php ;
fi;

####### add robots.txt #####
if [ dev=='y'  ] ; then \
  	echo 'this is a dev site, we will add a robots.txt file'
	echo '-->adding robots.txt';
	cp "setup_files/robots.txt" ${folder}/robots.txt ;
fi ;


###### fin #######
echo ------successfully completed------ ;
echo 'WARNING: dont forget to check robots.txt can be seen by google, by going to '${url}'/robots.txt';
