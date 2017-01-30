class solr {
    
    $apache_packages = $osfamily ? {
        "Debian" => ["apache2"],
        "RedHat" => ["httpd"],
    }
    
    
    $javapackage = $operatingsystem ? {
        "Ubuntu" => [
            "openjdk-7-jre-headless",

        ],
        "CentOS" => [

        ],
    }
    
    $solrpackage = $operatingsystem ? {
        "Ubuntu" => [
            "solr-jetty",

        ],
        "CentOS" => [

        ],
    }
    
    # install packages
    package { $javapackage:
        ensure => present,
    }
    package { $solrpackage:
        ensure => present,
        require => [Package[$javapackage],Package[$apache_packages]],
    }

    if $operatingsystem == 'Ubuntu' {
        exec { "rotatelogs-bugfix":
        cwd => "/",
        command => "sed -i 's/^ROTATELOGS=.*$/ROTATELOGS=\\/usr\\/bin\\/rotatelogs/' /etc/init.d/jetty",
        require => Package[$solrpackage],
        before => Exec["restart-jetty"],
        }
        
    }
    # create collection dirs for solr
    
    file { "/var/lib/solr/collection_gpcrmd/":
        ensure => directory,
        recurse => true,
        purge => true,
        force => true,
        owner => jetty,
        group => jetty,
        mode   => '0750',
        before => File["/var/lib/solr/collection_gpcrmd/data"],
        require => Package[$solrpackage],
    }
    
    
    file { "/var/lib/solr/collection_gpcrmd/data":
        ensure => directory,
        recurse => true,
        purge => true,
        force => true,
        owner => jetty,
        group => jetty,
        mode   => '0750',
        before => File["/etc/solr/solr.xml"],
        require => [File["/var/lib/solr/collection_gpcrmd/"],Package[$solrpackage]],
    }
    
    
    # create solr config
    file { "/etc/solr/solr.xml":
        ensure => present,
        replace => true,
        mode => 0744,
        owner => root,
        group => root,
        source => "/protwis/conf/protwis_puppet_modules/solr/config/solr.xml",
        require => Package[$solrpackage],
    }
    
    file { "/etc/default/jetty":
        ensure => present,
        replace => true,
        links => follow,
        mode => 0744,
        owner => root,
        group => root,
        source => "/protwis/conf/protwis_puppet_modules/solr/config/jetty",
        require => Package[$solrpackage],
    }
    
    

    # symlink colection conf directory to git repository
    file { "/var/lib/solr/collection_gpcrmd/conf":
        ensure => link,
        target => "/protwis/sites/protwis/solr/collection_gpcrmd/conf/",
        require => [File["/var/lib/solr/collection_gpcrmd/data"],Package[$solrpackage]],
    }
    
    # disable jetty on startup
    exec { "disable-jetty-on-startup":
        cwd => "/",
        command => "update-rc.d jetty disable",
        require => [File["/var/lib/solr/collection_gpcrmd/data"],Package[$solrpackage],File["/var/lib/solr/collection_gpcrmd/conf"],File["/etc/solr/solr.xml"]],
    }
    
    # restart jetty to apply new configuration
    exec { "restart-jetty":
        cwd => "/",
        command => "/etc/init.d/jetty restart",
        require => [File["/var/lib/solr/collection_gpcrmd/data"],Package[$solrpackage],File["/var/lib/solr/collection_gpcrmd/conf"],File["/etc/solr/solr.xml"],File["/etc/default/jetty"]],
    }
        
    # build indexes
    exec { "build-indexes":
        cwd => "/protwis/sites/protwis",
        command => "/env/bin/python3 manage.py rebuild_index --noinput",
        require => [Exec["import-db-dump"],Exec["restart-jetty"],Python::Puppet::Install::Pip[$python::pip_packages],Exec["install-rdkit"]],
    }
    
}
