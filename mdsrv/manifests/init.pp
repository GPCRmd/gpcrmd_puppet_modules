class mdsrv {
    $release="v0.3.tar.gz"
    $url="https://github.com/arose/mdsrv/archive/"
    $pip_packages = ["numpy==1.11","scipy","cython"]
    
    
    # install apache
    $apache_packages = $osfamily ? {
        "Debian" => ["apache2"],
        "RedHat" => ["httpd", "httpd-devel"],
    }
    
    case $osfamily {
        'Debian': {
            $apache_user='www-data'
        }
        'RedHat': {
            $apache_user='apache'
        }
        'CentOS': {
            $apache_user='apache'
        }
    }

    # download mdsrv
    exec { "download-mdsrv":
        command => "curl -sLo /protwis/conf/protwis_puppet_modules/mdsrv/mdsrv.tar.gz ${url}${release}",
        timeout => 600,
    }
    
    file { "/var/www/":
        ensure => directory,
        recurse => false,
        purge => false,
        force => true,
        mode   => '0750',
        group => $apache_user,
        require => Package[$apache_packages],
    }
    
    # install mdsrv
    exec { "install-mdsrv":
        cwd => "/protwis/conf/protwis_puppet_modules/mdsrv/",
        command => "bash ./scripts/mdsrv.sh ${apache_user}",
        require => [File["/var/www/"], Exec["download-mdsrv"],Python::Puppet::Install::Pip[$pip_packages]],
        timeout => 600,
    }
    
    file { "/var/www/mdsrv/app.cfg":
        ensure => present,
        source => "/protwis/conf/protwis_puppet_modules/mdsrv/config/app.cfg",
        require => Exec["install-mdsrv"],
    }

    file { "/var/www/mdsrv/mdsrv.wsgi":
        ensure => present,
        source => "/protwis/conf/protwis_puppet_modules/mdsrv/config/mdsrv.wsgi",
        require => Exec["install-mdsrv"],
    }

    file { '/var/www/html':
       ensure => 'link',
       recurse => true,
       purge => true,
       force => true,
       target => '/protwis/sites/protwis/mdsrv_static',
       require => File["/var/www/"],
    }
    
    
}
