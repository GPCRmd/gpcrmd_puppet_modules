class clean_cache {
  require python
  file {"remove_django_cache_directory":
    ensure => absent,
    path => "/tmp/django_cache",
    recurse => true,
    purge => true,
    force => true,
   }

  file {"remove_django_cache_directory_dev":
    ensure => absent,
    path => "/tmp/django_cache_dev",
    recurse => true,
    purge => true,
    force => true,
    require => File["remove_django_cache_directory"],
    
  }

}
