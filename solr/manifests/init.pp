class solr {
    require import_db
    $apache_packages = $osfamily ? {
        "Debian" => ["apache2"],
        "RedHat" => ["httpd"],
    }


    $javapackage = $operatingsystem ? {
        "Ubuntu" => [
            "openjdk-7-jre-headless",

        ],
        "CentOS" => [
            "java-1.8.0-openjdk",
        ],
    }

    $solrpackage = $operatingsystem ? {
        "Ubuntu" => [
            "solr-jetty",

        ],
        "CentOS" => [
            "lsof",
            "curl",
            "logrotate"
        ],
    }

    $jetty_solr = false
    if $operatingsystem == "Ubuntu" {
        $jetty_solr = true

    }

    if $jetty_solr {
        $solr_user = "jetty"
    } else {
        $solr_user = "solr"
    }
    # install packages

    package { $javapackage:
        ensure  => present,
        require => Exec["update-package-repo"],
    }
    package { $solrpackage:
        ensure  => present,
        require => [Package[$javapackage],Package[$apache_packages],Exec["update-package-repo"]],
    }
    if !$jetty_solr {
    # download solr
        exec { "download-sorl":
            cwd     => "/protwis/conf/protwis_puppet_modules/solr/",
            command => "curl -sLO https://archive.apache.org/dist/lucene/solr/6.4.2/solr-6.4.2.tgz",
            timeout => 600,
            require => Package[$solrpackage],
        }
        exec { "untar-solr":
            cwd     => "/protwis/conf/protwis_puppet_modules/solr/",
            command => "tar xzf solr*.tgz solr*/bin/install_solr_service.sh --strip-components=2",
            require => Exec["download-sorl"],
        }
        exec { "install-solr":
            cwd     => "/protwis/conf/protwis_puppet_modules/solr/",
            command => "bash ./install_solr_service.sh solr*.tgz -f",
            require => Exec["untar-solr"],
        }
        $solr_install_step = Exec["install-solr"]

        # create collection dirs for solr

        file { "/var/solr/data/collection_gpcrmd/":
            ensure  => directory,
            recurse => true,
            purge   => true,
            force   => true,
            owner   => $solr_user,
            group   => $solr_user,
            mode    => '0750',
            require => $solr_install_step,
        }

        file { "/var/solr/data/collection_gpcrmd/data":
            ensure  => directory,
            recurse => true,
            purge   => true,
            force   => true,
            owner   => $solr_user,
            group   => $solr_user,
            mode    => '0750',
            require => File["/var/solr/data/collection_gpcrmd/"],
        }

        # create solr core config
        file { "/var/solr/data/collection_gpcrmd/core.properties":
            ensure  => present,
            replace => true,
            mode    => 0744,
            owner   => root,
            group   => root,
            source  => "/protwis/conf/protwis_puppet_modules/solr/config/core.properties",
            require => File["/var/solr/data/collection_gpcrmd/"],
        }

        # symlink colection conf directory to git repository
        file { "/var/solr/data/collection_gpcrmd/conf":
            ensure  => link,
            target  => "/protwis/sites/protwis/solr/collection_gpcrmd/conf/",
            require => File["/var/solr/data/collection_gpcrmd/"],
            notify  => Exec["restart-solr"],
        }

        exec { "restart-solr":
            command => "service solr restart",
            require => [
                File["/var/solr/data/collection_gpcrmd/data"],
                File["/var/solr/data/collection_gpcrmd/core.properties"],
                File["/var/solr/data/collection_gpcrmd/conf"]
            ],
        }

    }
    if $jetty_solr {
        $solr_install_step = Package[$solrpackage]
        if $operatingsystem == 'Ubuntu' {
            exec { "rotatelogs-bugfix":
            cwd     => "/",
            command => "sed -i 's/^ROTATELOGS=.*$/ROTATELOGS=\\/usr\\/bin\\/rotatelogs/' /etc/init.d/jetty",
            require => Package[$solrpackage],
            before  => Exec["restart-solr"],
            }



        }
        # create collection dirs for solr

        file { "/var/lib/solr/collection_gpcrmd/":
            ensure  => directory,
            recurse => true,
            purge   => true,
            force   => true,
            owner   => $solr_user,
            group   => $solr_user,
            mode    => '0750',
            before  => File["/var/lib/solr/collection_gpcrmd/data"],
            require => $solr_install_step,
        }


        file { "/var/lib/solr/collection_gpcrmd/data":
            ensure  => directory,
            recurse => true,
            purge   => true,
            force   => true,
            owner   => $solr_user,
            group   => $solr_user,
            mode    => '0750',
            before  => File["/etc/solr/solr.xml"],
            require => [File["/var/lib/solr/collection_gpcrmd/"],$solr_install_step],
        }

        # create solr config
        file { "/etc/solr/solr.xml":
            ensure  => present,
            replace => true,
            mode    => 0744,
            owner   => root,
            group   => root,
            source  => "/protwis/conf/protwis_puppet_modules/solr/config/solr.xml",
            require => $solr_install_step,
        }

        file { "/etc/default/jetty":
            ensure  => present,
            replace => true,
            links   => follow,
            mode    => 0744,
            owner   => root,
            group   => root,
            source  => "/protwis/conf/protwis_puppet_modules/solr/config/jetty",
            require => Package[$solrpackage],
        }



        # symlink colection conf directory to git repository
        file { "/var/lib/solr/collection_gpcrmd/conf":
            ensure  => link,
            target  => "/protwis/sites/protwis/solr/collection_gpcrmd/conf/",
            require => [File["/var/lib/solr/collection_gpcrmd/data"],$solr_install_step],
        }

        # disable jetty on startup
        exec { "disable-jetty-on-startup":
            cwd     => "/",
            command => "update-rc.d jetty disable",
            require => [File["/var/lib/solr/collection_gpcrmd/data"],$solr_install_step,File["/var/lib/solr/collection_gpcrmd/conf"],File["/etc/solr/solr.xml"]],
        }

        # restart jetty to apply new configuration
        exec { "restart-solr":
            cwd     => "/",
            command => "/etc/init.d/jetty restart",
            require => [File["/var/lib/solr/collection_gpcrmd/data"],$solr_install_step,File["/var/lib/solr/collection_gpcrmd/conf"],File["/etc/solr/solr.xml"],File["/etc/default/jetty"]],
        }
    }

    # build indexes
    exec { "build-indexes":
        cwd     => "/protwis/sites/protwis",
        command => "/env/bin/python3 manage.py rebuild_index --noinput",
        require => [Exec["import-db-dump"],Python::Puppet::Install::Pip[$Python::pip_packages],Exec["install-rdkit"]],
        notify  => [File["remove_django_cache_directory"],Exec["restart-solr"]],
        timeout => 3600,
    }

}
