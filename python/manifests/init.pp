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

    $packages = $operatingsystem ? {
        "Ubuntu" => [
                "python3.4",
                "python3-pip",
                # for python2, will be removed
                "python-biopython",
                "python-rdkit",
                "python3-numpy",
                "python3-scipy",
                "python-yaml",
        ],
        "CentOS" => [
                "python34",
                "python34-devel",
                # for python2, will be removed
                "python-biopython",
                "rh-python34-numpy",
                "rh-python34-scipy",
                #"python-rdkit",
                "PyYAML",
        ],
    }

    # install packages
    package { $packages:
        ensure => present,
        require => Exec["update-package-repo"]
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
            "CentOS" => "wget https://bootstrap.pypa.io/get-pip.py;python3 get-pip.py",
            "Ubuntu" => "apt install -y python3-pip",
        },
	require => Package[$packages],
    }

    # install virtualenv (using the system wide pip3 installation)
    exec { "install-virtualenv":
        command => "pip3 install virtualenv",
        require => Exec["install-pip"],
    }

    # create virtualenv
    exec { "create-virtualenv":
        command => "virtualenv -p python3 /env",
        require => Exec["install-virtualenv"],
    }


    


    # install packages inside the virtualenv with pip
    define puppet::install::pip ($pip_package = $title) {
        exec { "install-$pip_package":
            command => "/env/bin/pip3 install $pip_package",
            timeout => 1800,
        }
    }

    $pip_packages_first = ["psycopg2==2.6","django==1.9","numpy==1.11","scipy","cython","pysolr==3.6"]
    puppet::install::pip { $pip_packages_first: 
    	require => [Package["postgresql-9.3", "postgresql-contrib-9.3","solr-jetty"],Package[$packages], Exec["create-virtualenv"]]
    }

    $pip_packages = ["ipython", "certifi",  "django-debug-toolbar", "biopython==1.67", "xlrd", "PyYAML",
        "djangorestframework==3.4", "django-rest-swagger==0.3.10", "XlsxWriter", "sphinx","requests==2.11.1", "cairocffi", "Pillow", "defusedxml","mdtraj","django-graphos","django-haystack==2.5"]

    puppet::install::pip { $pip_packages:
	before => Exec["build-indexes"],
	require => [Puppet::Install::Pip[$pip_packages_first], Exec["create-virtualenv"]],
    }
}
