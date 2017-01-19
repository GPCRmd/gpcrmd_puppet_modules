tar -xvzf mdsrv.tar.gz
mv mdsrv* /var/www/mdsrv
cd /var/www/mdsrv
/env/bin/python setup.py install
chgrp -R $1 /var/www/mdsrv
chown -R g+rW /var/www/mdsrv
chown -R g-w /var/www/mdsrv
chown -R o-rwx /var/www/mdsrv

