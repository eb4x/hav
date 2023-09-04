class profile::openssl (
  $ssl_path         = '/etc/pki/tls',
  $ca_dir           = '/opt/himlar/provision/ca',
  Hash[String, Hash] $certs = {},
) {

  include ::openssl

  file { ['/opt', '/opt/himlar', '/opt/himlar/provision', $ca_dir, "${ca_dir}/intermediate", "${ca_dir}/intermediate/private"]:
    ensure => directory,
  }
  -> file { "${ca_dir}/passfile":
    #content => 'mysecure_password',
    content => extlib::cache_data('namespace', 'openssl_passfile', extlib::random_password(32)),
  }
  -> file { "${ca_dir}/intermediate/openssl.cnf":
    #source => "puppet:///modules/${module_name}/openssl.cnf",
    content => file("${module_name}/openssl.cnf"),
  }
  -> ssl_pkey { "${ca_dir}/intermediate/private/ca.key.pem":
    ensure   => 'present',
    size => 4096,
    password => $facts['openssl_passfile'],
  }
  -> notify { "passfile: ${facts['openssl_passfile']}": }

  #create_resources('profile::openssl::cert', $certs,
  #  { require => Exec['generate /tmp/serial']})

  exec { 'generate /tmp/serial':
    command => '/bin/date +%s > /tmp/serial',
    creates => '/tmp/serial'
  }

  #exec { "${ssl_path}/certs/cachain.pem":
  #  command => "/bin/cp ${ca_dir}/intermediate/certs/ca-chain.cert.pem ${ssl_path}/certs/cachain.pem",
  #  creates => "${ssl_path}/certs/cachain.pem"
  #}

  dhparam { "${ssl_path}/certs/dhparam.pem":
    ensure => present,
    size   => 2048,
  }
}
