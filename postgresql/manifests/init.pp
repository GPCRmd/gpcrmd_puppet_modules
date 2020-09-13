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

    if $osfamily == "Debian"  {
        $postgresql_version = "9.3"
    } elsif $osfamily == "RedHat" {
        $postgresql_version = "9.6"
        $postgresql_version2 = "96"
    }

    # package install list
    $packages = $osfamily ? {
        "Debian" => [
            "postgresql-${$postgresql_version}",
            "postgresql-contrib-${$postgresql_version}",
            "postgresql-server-dev-${$postgresql_version}",
            "postgresql-server-dev-all",
            "dctrl-tools",
            "lsb-release",
            "make",
        ],
        "RedHat" => [
            "postgresql${$postgresql_version2}",
            "postgresql${$postgresql_version2}-contrib",
            "postgresql${$postgresql_version2}-server",
            "postgresql${$postgresql_version2}-devel",
        ],
    }

    $postgresql_service_name = $osfamily ? {
        "Debian" => 'postgresql',
        "RedHat" => "postgresql-${$postgresql_version}",
    }

    # install packages
    package { $packages:
        ensure  => present,
        require => Exec["update-package-repo"]
    }

    # RedHat distros require extra commands to init postgres
    if $osfamily == "RedHat" {

/*      exec { "add-postgresql-repo":
            command => "/usr/bin/yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
            before => Package[$packages],
        } */

        package { "pgdg-redhat-repo":
            provider => "rpm",
            ensure   => present,
            source   => "https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm",
            before   => Package[$packages],

        }

        exec { "init-postgres-db":
            command => "/usr/bin/true",
            unless  => "/usr/pgsql-${postgresql_version}/bin/postgresql${postgresql_version2}-setup initdb", # if this command fails (DB already initialized, do nothing)
            require => Package[$packages],
        }

        exec { "add-postgres-to-path-sh":
            provider => shell,
            command  => "PROFILED_FILE='/etc/profile.d/pgsql${postgresql_version2}.sh'; \
            echo 'export PATH=\"\$PATH\":/usr/pgsql-${postgresql_version}/bin/' > \"\$PROFILED_FILE\"; \
            source \"\$PROFILED_FILE\"",
            require  => Exec['init-postgres-db'],
        }

        exec { "allow-postgres-password-auth":
            command => "sed -i \"s/ident/md5/g\" /var/lib/pgsql/${postgresql_version}/data/pg_hba.conf",
            require => Exec['init-postgres-db'],
        }

        exec { "start-postgres-server":
            command => "systemctl start postgresql-${postgresql_version};systemctl enable postgresql-${postgresql_version}",
            require => Exec['allow-postgres-password-auth'],
        }
    }

    unless $::production_config {
        $pg_hba_string = '"\nhost    all             all              10.0.2.2/32             md5"'
        $pg_config_path = $osfamily ? {
            "Debian" => "/etc/postgresql/${$postgresql_version}/main",
            "RedHat" => "/var/lib/pgsql/${postgresql_version}/data",
        }
        exec { "allow-postgres-password-auth-vm":
                command => "printf ${pg_hba_string} >> ${pg_config_path}/pg_hba.conf; 
                            sed -i 's/^#\\(listen_addresses.*\\)localhost\\(.\\)\\(.*$\\)/\\1*\\2         \\3/' ${pg_config_path}/postgresql.conf",
                require => $osfamily ? {
                    "Debian" => Package[$packages],
                    "RedHat" => Exec['init-postgres-db'],
                },
                notify  => Service[$postgresql_service_name]
        }
    }



    service { $postgresql_service_name:
            ensure  => 'running',
            require => Package[$packages],
    }

}
