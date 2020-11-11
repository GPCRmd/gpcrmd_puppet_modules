class apache {
    require import_db
    # install apache
    $apache_packages = $osfamily ? {
        "Debian" => ["apache2","libapache2-mod-xsendfile"],
        "RedHat" => ["httpd", "httpd-devel","mod_xsendfile"],
    }
    $apache_main_package = $apache_packages[0]

    $virtualhost_file_destination_path = "/etc/${apache_main_package}/sites-available/000-default.conf"
    $virtualhost_enabled_file_destination_path = "/etc/${apache_main_package}/sites-enabled/000-default.conf"
 

    package { $apache_packages:
        ensure  => present,
        require => Exec["update-package-repo"],
    } ->
    # install mod_wsgi
    case $osfamily {
        'Debian': {
            package { "libapache2-mod-wsgi-py3":
                ensure  => present,
                require => [ Exec["update-package-repo"], Package[$apache_main_package] ],
            }
        }
        'RedHat': {
            python::puppet::install::pip { "mod-wsgi":
                # require => [ Exec["install-pip"], Package[$apache_packages, "python34-devel"], Exec["install-boost"]],
                require => [ Exec["install-pip"], Package[$apache_packages, "python34-devel"]],
            }
            -> exec { "enable-mod_wsgi":
                command => "echo 'LoadModule wsgi_module /env/lib64/python3.4/site-packages/mod_wsgi/server/mod_wsgi-py34.cpython-34m.so' >> /etc/httpd/conf/httpd.conf",
            }
        }
    }

    # enable apache on boot
    case $osfamily {
        'RedHat': {
            exec { "enable-apache":
                command => "systemctl enable httpd.service",
                require => Package[$apache_main_package],
            }
        }
    }




    # enable apache included plugins
    case $osfamily {
        'Debian': {
            exec { "enable-apache-plugins":
                command => "a2enmod rewrite proxy proxy_http xsendfile",
                timeout => 3600,
                require => Package[$apache_main_package],
                before  => File[$virtualhost_enabled_file_destination_path],
                notify  => Service[$apache_main_package],
            }
        }
    }


    # create dirs
    file { "/etc/$apache_main_package/sites-available":
        ensure => directory,
        recurse => true,
        purge => true,
        force => true,
        before => File[$virtualhost_file_destination_path],
        require => Package[$apache_main_package],
    }
    file { "/etc/$apache_main_package/sites-enabled":
        ensure => directory,
        recurse => true,
        purge => true,
        force => true,
        before => File["/etc/$apache_main_package/sites-enabled/000-default.conf"],
        require => Package[$apache_main_package],
    }
    # this is to allow logging under apache
    file { "/var/www/logs":
        ensure => directory,
        recurse => true,
        purge => true,
        force => true,
        mode   => '0777',
        before => File["/etc/$apache_main_package/sites-enabled/000-default.conf"],
        require => Package[$apache_main_package],
    }

    # add sites-enabled dir to main apache config (RedHat OSes only)
    if $osfamily == 'RedHat' {
        exec { "add-sites-enabled-dir-to-config":
            unless  => "grep -e \"^\s*[Ii][nN][cC][lL][uU][dD][eE][Oo][pP][tT][iI][oO][nN][aA][lL]\\s\\+\
[\\\"']\\?\\(\\(\\./\\)\\|\\(/etc/${apache_main_package}/\\)\\)\\?sites-enabled/[\\\"']\\?\\*\\.conf\\s*$\" /etc/${apache_main_package}/conf/httpd.conf",
            command => "echo 'IncludeOptional sites-enabled/*.conf' >> /etc/${apache_main_package}/conf/httpd.conf",
            require => File["/etc/$apache_main_package/sites-enabled"],
            before  => File[$virtualhost_file_destination_path],
        }
        exec { "comment-listen-ports-conf-in-config":
            command => "sed -ir 's/^\\(\\s*Listen\\s\\+\\)/#\\1/gi' /etc/${apache_main_package}/conf/httpd.conf",
            require => [File["/etc/$apache_main_package/sites-enabled"], File["/etc/$apache_main_package/ports.conf"]],
            before  => Service[$apache_main_package],
        }
        exec { "add-ports-conf-to-config":
            unless  => "grep -e \"^\\s*[Ii][nN][cC][lL][uU][dD][eE][Oo][pP][tT][iI][oO][nN][aA][lL]\\s\\+\
[\\\"']\\?\\(\\(\\./\\)\\|\\(/etc/${apache_main_package}/\\)\\)\\?ports.conf[\\\"']\\?s*$\" /etc/${apache_main_package}/conf/httpd.conf",
            command => "echo 'IncludeOptional ports.conf' >> /etc/${apache_main_package}/conf/httpd.conf",
            require => [File["/etc/$apache_main_package/sites-enabled"], File["/etc/$apache_main_package/ports.conf"]],
            before  => Service[$apache_main_package],
        }
    }

    # allow traffic on port 80 (RedHat OSes only)
    if $osfamily == 'RedHat' {
        exec { "open-port-80":
            onlyif  => "firewall-cmd --state",
            command => "firewall-cmd --zone=public --add-port=80/tcp",
        }
        exec { "open-port-80-permanent":
            onlyif  => "firewall-cmd --state",
            command => "firewall-cmd --zone=public --add-port=80/tcp --permanent",
        }
        exec { "open-port-80-permanent2":
            unless  => "firewall-cmd --state",
            command => "systemctl start firewalld; firewall-cmd --zone=public --add-port=80/tcp --permanent; systemctl stop firewalld",
        }
    }

    # create apache config
    file { $virtualhost_file_destination_path:
        ensure => present,
        source => "/protwis/conf/protwis_puppet_modules/apache/config/virtualhost",
        require => Package[$apache_main_package],
    }

    # replace 'www-data' user and group by 'apache' for RedHat family systems
    exec {"fix-apache-user-000-default.conf":
        provider  => shell,
        command   => "FILE='${virtualhost_file_destination_path}'; cp \"\$FILE\" \"\${FILE}.bkp\"; sed -i 's/www-data/apache/g' \"\$FILE\"",
        subscribe => File[$virtualhost_file_destination_path],
    }

    # enable apache ports apache
    file { "/etc/$apache_main_package/ports.conf":
        ensure  => present,
        source  => "/protwis/conf/protwis_puppet_modules/apache/config/ports.conf",
        require => Package[$apache_main_package],
        before  => Service[$apache_main_package],
    }

    # symlink apache site to the site-enabled directory
    file { $virtualhost_enabled_file_destination_path:
        ensure  => link,
        target  => $virtualhost_file_destination_path,
        require => File[$virtualhost_file_destination_path],
        notify  => Service[$apache_main_package],
    }

    #generate blast database and collect static files before starting apache
    exec { "build_blast_db":
        cwd         => "/protwis/sites/protwis",
        command     => "/env/bin/python3 manage.py build_blast_database",
        environment => ["LC_ALL=en_US.UTF-8"],
        require     => [Package["ncbi-blast-2.11.0+-1"] , Exec["import-db-dump", "install-rdkit"], Python::Puppet::Install::Pip[$python::pip_packages]],
        notify      => File["remove_django_cache_directory"],
    }
    exec { "collect-static":
        cwd     => "/protwis/sites/protwis",
        command => "/env/bin/python3 manage.py collectstatic --noinput",
        require => [Exec["import-db-dump", "install-rdkit"], Python::Puppet::Install::Pip[$python::pip_packages]],
        notify  => File["remove_django_cache_directory"],
    }

    # starts the apache2 service once the packages installed, and monitors changes to its configuration files and
    # reloads if nesessary
    service { $apache_main_package:
        ensure    => running,
        require   => [ Package[$apache_main_package],  Exec["collect-static"]],
    }
}
