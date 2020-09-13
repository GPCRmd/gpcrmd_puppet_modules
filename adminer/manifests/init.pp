class adminer {

    $apache_packages = $osfamily ? {
        "Debian" => ["apache2"],
        "RedHat" => ["httpd", "httpd-devel"],
    }
    $apache_main_package = $apache_packages[0]

    if $osfamily == "Debian" {

        # package install list
        $packages = [
            "adminer",
        ]


        # install packages
        package { $packages:
            ensure => present,
            require => [Package[$apache_main_package],Exec["update-package-repo"]]
        }


        # configure adminer
        file { "/etc/apache2/sites-enabled/adminer.conf":
            ensure => present,
            source => "/protwis/conf/protwis_puppet_modules/adminer/config/apache.conf",
            require => Package["adminer"],
            notify => Service[$apache_main_package],
        }

        # starts the apache2 service once the packages installed, and monitors changes to its configuration files and
        # reloads if nesessary
        #    service { "apache2":
        #    ensure => running,
        #    require => Package["apache2"],
        #}
    }
}
