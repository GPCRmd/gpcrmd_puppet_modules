class tools {

    # package install list
    $packages = $operatingsystem ? {
        "Ubuntu" => [
            "git",
            "openbabel",
            "expect",
            "htop",
            "vim",
            "clustalo",
            "ncbi-blast+",
        ],
        "CentOS" => [
            "git",
            "openbabel",
            "expect",
            "htop",
            "wget",
            "clustal-omega",
            "perl-Archive-Tar",
            "perl-Digest-MD5",
            "perl-List-MoreUtils",
            "argtable",
            "argtable-devel",

        ],
    }

    # install packages
    package { $packages:
        ensure => present,
        require => Exec["update-package-repo"],
    }
    package { "ncbi-blast-2.10.1+-1":
            provider => "rpm",
            ensure   => present,
            source   => "https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.10.1+-1.x86_64.rpm",
            require  => Package[$packages],

    }
}
