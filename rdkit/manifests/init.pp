class rdkit {
    require boost
    $release="Release_2016_03_1.tar.gz"
    $url="https://github.com/rdkit/rdkit/archive/"
    $pip_packages = ["numpy","cairocffi", "Pillow"]
    $packages = $operatingsystem ? {
        "Ubuntu" => [
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
            "python3-tk",
            "libcairo2",
        ],
        "CentOS" => [
            "cmake",
            "sqlite",
            "sqlite-devel",
            "tcl-devel",
            "tk-devel",
            "readline-devel",
            "bzip2-devel",
            "libtiff-devel",
            "freetype-devel",
            "libwebp-devel",
            "lcms2-devel",
            "cairo",

        ],
    }

    # install packages
    package { $packages:
        ensure  => present,
        require => Exec["update-package-repo"],
    }

    # download rdkit
    exec { "download-rdkit":
        command => "curl -sLo /protwis/conf/protwis_puppet_modules/rdkit/rdkit.tar.gz ${url}${release}",
        timeout => 600,
        require => Package["curl"],
    }

    $install_rdkit_requirements = $operatingsystem ? {
        "Ubuntu" => [
            Exec["download-rdkit"],
            Package[$Python::packages],
            Package[$packages],
            Python::Puppet::Install::Pip[$Python::pip_packages],
            Package[$Boost::packages],
        ],
        "CentOS" => [
            Exec["download-rdkit"],
            Package[$Python::packages],
            Package[$packages],
            Python::Puppet::Install::Pip[$Python::pip_packages],
            Exec["install-boost"],
            Exec["add-usr_local_lib"],
        ],
    }


    # install rdkit
    exec { "install-rdkit":
        cwd     => "/protwis/conf/protwis_puppet_modules/rdkit/",
        command => "bash ./scripts/rdkit.sh ${Boost::boost_root} 2>&1 | tee install_log.txt",
        require => $install_rdkit_requirements,
        timeout => 3600,
    }

}
