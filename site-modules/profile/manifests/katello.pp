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

  if $facts['os']['selinux']['enabled'] {
    # Needs fix in candlepin/manifests/artemis.pp
    Selboolean['candlepin_can_bind_activemq_port']
    -> Service['tomcat']

    package { 'katello-selinux':
      ensure => installed,
      require => Class['katello::repo'],
      before => Service['foreman'],
    }
  }

  # XXX Fix pulpcore dependency, maybe fixed in a future release?
  package { 'python3-markuppy':
    ensure => present,
    require => Class['pulpcore::repo'],
    before => Class['pulpcore'],
  }

  include ::foreman_proxy_content

}
