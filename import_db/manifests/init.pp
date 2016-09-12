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

class import_db {
    require postgresql

    # create postgres user
    exec { "create-postgres-user":
        command => "expect -f /protwis/conf/protwis_puppet_modules/import_db/scripts/createuser.exp",
        require => $osfamily ? {
            "Debian" => Package["postgresql-9.3", "expect"],
            "RedHat" => [ Package["postgresql", "expect"], Exec["start-postgres-server"] ],
        }
    }

    # create postgres database
    exec { "create-postgres-db":
        command => "expect -f /protwis/conf/protwis_puppet_modules/import_db/scripts/createdb.exp",
        require => [ Exec["create-postgres-user"], Package["expect"], ],
    }

    # create db directory
    file { '/protwis/db':
        ensure => 'directory',
    }

    # download db dump
    exec { "dl-db-dump":
        command => "curl http://files.gpcrdb.org/protwis_sp.sql.gz > /protwis/db/protwis.sql.gz",
        timeout => 3600,
        require => [Exec["create-postgres-db"], File['/protwis/db']],
    }

    # extract db dump
    exec { "extract-db-dump":
        cwd => "/protwis/db",
        command => "gunzip -f protwis.sql.gz",
        require => Exec["dl-db-dump"],
    }

    # import db dump
    exec { "import-db-dump":
        command => "expect -f /protwis/conf/protwis_puppet_modules/import_db/scripts/importdb.exp",
        timeout => 3600,
        require => [ Exec["extract-db-dump"], Package["expect"], ],
    }
}
