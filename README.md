# droplet-setup

#### requirements
- nginx
- mysql
- www-data to be in your deployment user's group (to allow write access to some web folders for magento)

#### installation

copy setup_files/mysqlDetails.example to setup_files/mysqlDetails.
change the permissions to allow it to be run.
update the details in the new file.



#### notes
its always advisable that any server image that you use multiple fior multiple sites, to require a password change the next time its logged into after creation. This stops the same apssword being used for all of them.

using 

chage -d 0 {user-name}

e.g.

chage -d 0 paul
