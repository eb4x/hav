class profile::katello (

) {

  class { '::candlepin::repo':
    version => '4.1',
  }

  include ::katello
  include ::katello::repo

  Class['katello::repo']
  -> Class['certs::install', 'katello']

  Class['pulpcore::repo']
  -> Package['postgresql-evr']

  # XXX Fix pulpcore dependency, maybe fixed in a future release?
  package { 'python3-markuppy':
    ensure => present,
    require => Class['pulpcore::repo'],
    before => Class['pulpcore'],
  }

  include ::pulpcore::repo
  include ::foreman_proxy_content

  selinux::port { 'tomcat_candlepin_port':
    seltype => 'http_port_t',
    protocol => 'tcp',
    port => 23443,
    before => Service['tomcat'],
  }
}
