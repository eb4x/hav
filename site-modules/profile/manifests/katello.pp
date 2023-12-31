class profile::katello (

) {

  include ::katello
  include ::katello::repo

  Class['katello::repo']
  -> Class['certs::install', 'katello']

  include ::pulpcore::repo
  Class['pulpcore::repo']
  -> Package['postgresql-evr']

  include ::candlepin::repo

  # XXX Fix pulpcore dependency, maybe fixed in a future release?
  package { 'python3-markuppy':
    ensure => present,
    require => Class['pulpcore::repo'],
    before => Class['pulpcore'],
  }

  include ::foreman_proxy_content

  selinux::port { 'tomcat_candlepin_port':
    seltype => 'http_port_t',
    protocol => 'tcp',
    port => 23443,
    before => Service['tomcat'],
  }
}
