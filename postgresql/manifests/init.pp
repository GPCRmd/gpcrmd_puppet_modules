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

class postgresql {
    # package install list
    $packages = $osfamily ? {
        "Debian" => [
            "postgresql-9.3",
            "postgresql-contrib-9.3",
	    "postgresql-server-dev-9.3",
            "postgresql-server-dev-all",
            "dctrl-tools",
            "lsb-release",
            "make",
        ],
        "RedHat" => [
            "postgresql",
            "postgresql-contrib",
            "postgresql-server",
            "postgresql-devel",
        ],
    }

    # install packages
    package { $packages:
        ensure => present,
        require => Exec["update-package-repo"]
    }

    # RedHat distros require extra commands to init postgres
    if $osfamily == "RedHat" {
        exec { "init-postgres-db":
            command => "/usr/bin/true",
            unless => "postgresql-setup initdb", # if this command fails (DB already initialized, do nothing)
            require => Package[$packages],
        }

        exec { "allow-postgres-password-auth":
            command => 'sed -i "s/ident/md5/g" /var/lib/pgsql/data/pg_hba.conf',
            require => Exec['init-postgres-db'],
        }

        exec { "start-postgres-server":
            command => 'systemctl start postgresql;systemctl enable postgresql',
            require => Exec['allow-postgres-password-auth'],
        }
    }

    unless $::production_config {
                          
        $pg_hba_string = '"\nhost    all             all              10.0.2.2/32             md5"'
        $pg_config_path = $osfamily ? {
            "Debian" => "/etc/postgresql/9.3/main",
            "RedHat" => "/var/lib/pgsql/data",
        }
        exec { "allow-postgres-password-auth-vm":
                command => "echo ${pg_hba_string} >> ${pg_config_path}/pg_hba.conf; 
                            sed -i 's/^#\\(listen_addresses.*\\)localhost\\(.\\)\\(.*$\\)/\\1*\\2         \\3/' ${pg_config_path}/postgresql.conf",
                require => Package[$packages],
                notify => Service['postgresql'],
        }
    }


    service { 'postgresql':
            ensure   => 'running',
            require => Package[$packages],
    }

}
