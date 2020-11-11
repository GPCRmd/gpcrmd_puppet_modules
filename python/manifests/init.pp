#    Copyright [2016] [Ismael Rodriguez Espigares and Alejandro Varela Rial]
#    Derived work from Protwis project Development environment (https://github.com/protwis/protwis_vagrant) by Vignir Isberg.
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
# 
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

class python {
    require postgresql
    $packages = $operatingsystem ? {
        "Ubuntu" => [
                "python3.4",
                "python3-pip",
                "python3.4-dev",
                # for python2, will be removed
                "python-biopython",
                "python-rdkit",
                "python3-matplotlib",
                "python3-numpy",
                "python3-scipy",
                "python-yaml",
                "libffi6",
                "libffi-dev",
                "libjpeg-dev",
                "zlib1g",
                "libyaml-cpp-dev",
        ],
        "CentOS" => [
                "python34",
                "python34-devel",
                # for python2, will be removed
                #"python2-biopython",
                #"python-rdkit",
                "PyYAML",
                "libyaml",
                "libyaml-devel",
                "libffi",
                "libffi-devel",
                "libjpeg-turbo-devel",
                "zlib",
                "zlib-devel",
                "gcc-c++"

        ],
    }


    $pip_packages_first_requeriments = $operatingsystem ? {
         "Ubuntu" => [
                Package[$Postgresql::packages],
                Package["solr-jetty"],
                Exec["create-virtualenv"]
        ],
        "CentOS" => [
                Package[$Postgresql::packages],
                Exec["create-virtualenv"],
                Exec['install-solr'],
                Exec["add-postgres-to-path-sh"],
                Exec["install-boost"],

        ],
    }


    # install packages
    package { $packages:
        ensure  => present,
        require => Exec["update-package-repo"]
    }


    if $operatingsystem == "CentOS" and false {

        #download conda
        exec { "download-conda":
            command => "curl -sLo /protwis/conf/protwis_puppet_modules/python/Miniconda3-4.6.14-Linux-x86_64.sh https://repo.anaconda.com/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh",
            require => Package["curl"],
        }

        #install conda
        exec { "install-conda":
            command => "bash /protwis/conf/protwis_puppet_modules/python/Miniconda3-4.6.14-Linux-x86_64.sh -b -p /opt/miniconda",
            require => Exec["download-conda"],
        }

        exec { "create-conda-env":
            command => "source /opt/miniconda/bin/activate; conda create --prefix /env python=3.4",
            require => Exec["install-conda"],
        }

    }


        # create a python3 symlink, because the names of the executable differ between OSes
        file { "/usr/local/bin/python3":
            ensure => "link",
            target => "/usr/bin/python3.4",
            require => $operatingsystem ? {
                "CentOS" => Package["python34"],
                "Ubuntu" => Package["python3.4"],
            }
        } ->
        # install pip
        exec { "install-pip":
            cwd => "/tmp",
            command => $operatingsystem ? {
                "CentOS" => "curl -sL https://bootstrap.pypa.io/3.4/get-pip.py > get-pip.py;python3 get-pip.py",
                "Ubuntu" => "apt install -y python3-pip",
            },
            require => Package[$packages],
        }


        # install virtualenv (using the system wide pip3 installation)
        exec { "install-virtualenv":
            command => "pip3 install pathlib2 virtualenv",
            require => Exec["install-pip"],
        }

        # create virtualenv
        exec { "create-virtualenv":
            command => "virtualenv -p python3 /env",
            require => Exec["install-virtualenv"],
        }


    # install packages inside the virtualenv with pip
    define puppet::install::pip (
            $run_before = "/usr/bin/true",
            $pip_package = $title,
            $options = "",
        ) {

        exec { "install-$pip_package":
            provider => shell,
            command  => "${run_before}; /env/bin/pip3 install ${options} \"$pip_package\"",
            timeout  => 1800,
        }
    }

    $pip_packages_first = ["django<1.10","numpy","scipy","cython","pysolr<3.7","flask","Pillow","PyYAML==3.12"]

    puppet::install::pip { "psycopg2<2.7":
        require    => $pip_packages_first_requeriments,
        run_before => "source '/etc/profile.d/pgsql${Postgresql::postgresql_version2}.sh'"
    }
    ->puppet::install::pip { $pip_packages_first:
        require => $pip_packages_first_requeriments,
    }

    $pip_packages = ["matplotlib<3.1","ipython", "certifi",  "django-debug-toolbar<1.10", "biopython<1.68", "xlrd",
        "djangorestframework<3.5", "django-rest-swagger==0.3.10", "XlsxWriter", "sphinx","requests<2.12", "cairocffi",
    "defusedxml","mdtraj","django-graphos","django-haystack<2.6","django-revproxy","django-sendfile","pandas","bokeh==1.2.0"]

    puppet::install::pip { $pip_packages:
            before  => Exec["build-indexes"],
            require => [Puppet::Install::Pip[$pip_packages_first], Exec["create-virtualenv"]],
    }

/*     #https://github.com/arose/mdsrv/pull/41
    #https://github.com/pypa/setuptools/issues/458
    exec { "mdsrv-bug-fix":
            command => "/env/bin/pip3 install \"setuptools<38\"",
            timeout => 1800,
            require => Puppet::Install::Pip[$pip_packages],
    } */


    puppet::install::pip { "mdsrv":
            before  => Exec["build-indexes"],
            require => Puppet::Install::Pip[$pip_packages],
    }

    # symlink for apache to mdsrv webapp
    file { "/env/lib/python3.4/site-packages/mdsrv":
        ensure  => directory,
        replace => false,
        require => Puppet::Install::Pip["mdsrv"],
    }

    file { "/env/lib/python3.4/site-packages/mdsrv/webapp":
        ensure  => link,
        replace => false,
        target  => "/env/lib64/python3.4/site-packages/mdsrv/webapp",
        require => Puppet::Install::Pip["mdsrv"],
    }
/*     exec { "restore-setuptools":
            command => "/env/bin/pip3 install --upgrade \"setuptools\"",
            timeout => 1800,
            require => [Exec["mdsrv-bug-fix"] ,Puppet::Install::Pip["mdsrv"] ],
    } */
}
