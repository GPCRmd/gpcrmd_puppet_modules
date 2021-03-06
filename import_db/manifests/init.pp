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
    require tools
    # create postgres user
    exec { "create-postgres-user":
        command => "expect -f /protwis/conf/protwis_puppet_modules/import_db/scripts/createuser.exp",
        require => $osfamily ? {
            "Debian" => [ Package["postgresql-9.3", "expect"], Service["postgresql"] ],
            "RedHat" => [ Package["postgresql", "expect"], Exec["start-postgres-server"], Service["postgresql"] ],
        }
    }

    # create postgres database
    exec { "create-postgres-db":
        command => "expect -f /protwis/conf/protwis_puppet_modules/import_db/scripts/createdb.exp",
        require => [ Exec["create-postgres-user"], Package["expect"], ],
    }

    # import prepare db
    exec { "import-db-prepare":
        command => "expect -f /protwis/conf/protwis_puppet_modules/import_db/scripts/preparedb.exp",
        require => [ Exec["create-postgres-db"], Package["expect"], ],
    }

    # create db directory
    file { '/protwis/db':
        ensure => 'directory',
    }


    # import db dump
    exec { "import-db-dump":
        command => "expect -f /protwis/conf/protwis_puppet_modules/import_db/scripts/importdb.exp",
        timeout => 3600,
        require => [ Exec["import-db-prepare"], Package["expect"], ],
    }
}
