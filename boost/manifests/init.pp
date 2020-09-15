class boost {
    $url="https://dl.bintray.com/boostorg/release/1.74.0/source/boost_1_74_0.tar.bz2"
    $packages = $operatingsystem ? {
        "Ubuntu" => [
            "build-essential",
            "libboost1.54-dev",
            "libboost-system1.54-dev",
            "libboost-thread1.54-dev",
            "libboost-serialization1.54-dev",
            "libboost-python1.54-dev",
            "libboost-regex1.54-dev",
        ],
        "CentOS" => [
            "libicu",
            "libicu-devel",
            "perl",
            # "boost",
            # "boost-devel",
            # "boost-system",
            # "boost-thread",
            # "boost-serialization",
            # "boost-regex",
        ],
    }

    $boost_root = $operatingsystem ? {
        "Ubuntu" => '/usr',
        "CentOS" => '/usr/local',
    }

    if $operatingsystem == "CentOS" {
        # install packages
        package { $packages:
            ensure  => present,
            require => Exec["update-package-repo"],
        }

/*      # download boost
        exec { "download-boost":
            command => "curl -sLo /protwis/conf/protwis_puppet_modules/boost/boost.tar.bz2 ${url}",
            timeout => 600,
            require => Package["curl"],
        } */

        file { '/protwis/conf/protwis_puppet_modules/boost/boost.tar.bz2':
            ensure => 'link',
            target => 'files/boost_1_61_0.tar.bz2',
        }

        # install rdkit
        exec { "install-boost":
            cwd     => "/protwis/conf/protwis_puppet_modules/boost/",
            command => "bash ./scripts/boost.sh 2>&1 | tee install_log.txt",
            require => [File['/protwis/conf/protwis_puppet_modules/boost/boost.tar.bz2'],Package[$Python::packages],Package[$packages],Exec["create-virtualenv"]],
            notify  => Exec["add-usr_local_lib"],
            timeout => 3600,
        }

        exec { "add-usr_local_lib":
                provider => shell,
                command  => "echo '/usr/local/lib' > '/etc/ld.so.conf.d/usr_local_lib.conf'; ldconfig"
        }
    }

}
