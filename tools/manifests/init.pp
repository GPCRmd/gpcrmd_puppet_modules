class tools {

    # package install list
    $packages = $operatingsystem ? {
        "Ubuntu" => [
            "openbabel",
            "expect",
            "htop",
            "vim",
            "clustalo",
            "ncbi-blast+",
        ],
        "CentOS" => [
            "openbabel",
            "expect",
            "htop",
            "clustal-omega",
            # "ncbi-blast+",
        ],
    }

    # install packages
    package { $packages:
        ensure => present,
        require => Exec["update-package-repo"]
    }
}
