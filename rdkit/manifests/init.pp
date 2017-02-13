class rdkit {
    require python
    $release="Release_2016_03_1.tar.gz"
    $url="https://github.com/rdkit/rdkit/archive/"
    $pip_packages = ["numpy==1.11","cairocffi", "Pillow"]
    $packages = $operatingsystem ? {
        "Ubuntu" => [
            "build-essential",
            "cmake",
            "sqlite3",
            "libsqlite3-dev",
            "libtiff4-dev",
            "libjpeg8-dev",
            "zlib1g-dev",
            "libfreetype6-dev",
            "liblcms2-dev",
            "libwebp-dev",
            "tcl8.5-dev",
            "tk8.5-dev",
            "python3.4-dev",
            "python3-tk",
            "libboost1.54-dev",
            "libboost-system1.54-dev",
            "libboost-thread1.54-dev",
            "libboost-serialization1.54-dev",
            "libboost-python1.54-dev",
            "libboost-regex1.54-dev",
            "libcairo2",
            "curl",
        ],
        "CentOS" => [
            "curl",
        ],
    }

    # install packages
    package { $packages:
        ensure => present,
        require => Exec["update-package-repo"],
    }

    # download rdkit
    exec { "download-rdkit":
        command => "curl -sLo /protwis/conf/protwis_puppet_modules/rdkit/rdkit.tar.gz ${url}${release}",
        timeout => 600,
        require => Package["curl"],
    }
    # install rdkit
    exec { "install-rdkit":
        cwd => "/protwis/conf/protwis_puppet_modules/rdkit/",
        command => "bash ./scripts/rdkit.sh",
        require => [Exec["download-rdkit"],Package[$packages],Python::Puppet::Install::Pip[$pip_packages]],
        timeout     => 3600,
    }
    
}
