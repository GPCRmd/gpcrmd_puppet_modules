tar -xvzf mdsrv.tar.gz -C /var/www/
mv /var/www/mdsrv* /var/www/mdsrv
mv mdsrv 
cd /var/www/mdsrv
/env/bin/python setup.py install
chgrp -R $1 /var/www/mdsrv
chmod -R g+rW /var/www/mdsrv
chmod -R g-w /var/www/mdsrv
chmod -R o-rwx /var/www/mdsrv

